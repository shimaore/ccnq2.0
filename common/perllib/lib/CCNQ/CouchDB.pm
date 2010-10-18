package CCNQ::CouchDB;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict; use warnings;

sub id_required { die 'ID is required' }

use Logger::Syslog;
use AnyEvent;
use AnyEvent::CouchDB;
use CCNQ::AE;
use Encode;

sub receive_ok {
  my ($rcv,$cv) = @_;
  my $result = CCNQ::AE::receive($cv);
  if($result && $result->{ok} eq 'true') {
    $rcv->send if $rcv;
    return 1;
  } else {
    $rcv->send(['Operation failed']) if $rcv;
    return 0;
  }
}

sub db {
  my ($uri,$db_name) = @_;
  my $couch = couch($uri);
  my $couch_db = $couch->db($db_name);
  return $couch_db;
}

sub install {
  my ($uri,$db_name,$designs) = @_;
  $designs ||= {};

  my $rcv = AE::cv;

  info("Creating CouchDB '${db_name}' database on server $uri");
  my $couch_db = db($uri,$db_name);

  my $install_designs = sub {
    # No designs
    if(! %$designs) {
      $rcv->send();
      return;
    }
    # Some designs
    while( my ($design_name,$design_content) = each %{$designs} ) {
      my $id = "_design/${design_name}";

      $rcv->begin;

      $design_content->{_id} = $id;
      $design_content->{language} ||= 'javascript';
      # $design_content->{views} should be specified

      info("Open old document $id");
      $db->open_doc($id)->cb(sub{
        my $old_doc = CCNQ::AE::receive(@_);
        if($old_doc) {
          $design_content->{_rev} = $old_doc->{_rev};
        }
        info("Create new document $id");
        $db->save_doc($design_content)->cb(sub{
          if(CCNQ::AE::receive(@_)) {
            $rcv->end();
          } else {
            error("Could not save design $id");
            $rcv->send();
          }
        });
      });
    }
  };

  my $cv = $db->info();
  $cv->cb(sub{
    info("Info for CouchDB '${db_name}' database");
    if(!CCNQ::AE::receive(@_)) {
      $db->create()->cb(sub{
        if(CCNQ::AE::receive(@_)) {
          $install_designs->();
        } else {
          error("Could not create database $db_name on server $uri");
          $rcv->send();
        }
      });
    } else {
      $install_designs->();
    }
  });
  return $rcv;
}

=head1 UPDATE

Updates in CCNQ::CouchDB are used to update a set of fields in an
existing record, or to create a new record (if the record key is not found).
Fields not specified in the parameters are left as they were in the existing
record.

This is different from the usual PUT semantics. To obtain proper PUT
semantics, do a delete() then an update().

=cut

=head2 update_cv($server_uri,$db_name,\%params)

Creates or modify a record based on the _id value in \%params.

Returns a condvar which will return the values saved.

=cut

sub update_cv {
  my ($uri,$db_name,$params) = @_;
  debug("CCNQ::CouchDB::update_cv(".CCNQ::AE::ppp(@_).")");

  my $rcv = AE::cv;

  unless($params->{_id}) {
    id_required();
  }

  # Insert / Update a CouchDB record
  my $couch_db = db($uri,$db_name);

  $couch_db->open_doc($params->{_id})->cb(sub{
    my $doc = CCNQ::AE::receive(@_);
    if(!$doc) {
      $doc = { _id => $params->{_id} };
    }

    # Only updates the specified fields, except any field whose name starts
    # with "_".
    # "[A]ny top-level fields within a JSON document containing a name
    # that starts with a _ prefix are reserved for use by CouchDB itself."
    for my $key (grep { !/^_/ } keys %{$params}) {
      $doc->{$key} = $params->{$key};
    }

    debug("CCNQ::CouchDB::update_cv: saving document: ".CCNQ::AE::ppp($doc));
    $couch_db->save_doc($doc)->cb(sub{ CCNQ::AE::receive(@_); $rcv->send($doc) });
  });
  return $rcv;
}

=head2 update_bulk_cv($server_uri,$db_name,\%params)

Creates or modify multiple records.

\%params->{docs} must contain the new documents. If a document contains
a key "_deleted", then that document will be deleted (rather than updated
or created).

Return a condvar that will indicates the number of successfully updated
documents.

=cut

sub update_bulk_cv {
  my ($uri,$db_name,$params) = @_;
  debug("CCNQ::CouchDB::update_cv(".CCNQ::AE::ppp(@_).")");

  my $rcv = AE::cv;

  unless($params->{docs}) {
    die "docs not provided";
  }

  # Insert / Update / Delete CouchDB records
  my $couch_db = db($uri,$db_name);

  for my $new_data (@{$params->{docs}}) {
    my $id = $new_data->{_id};

    $rcv->begin;

    $couch_db->open_doc($id)->cb(sub{
      my $doc = CCNQ::AE::receive(@_);
      if(!$doc) {
        $doc = { _id => $id };
      }
      for my $key (grep { !/^_/ } keys %{$new_data}) {
        $doc->{$key} = $new_data->{$key};
      }

      my $op;
      if(delete $new_data->{_deleted}) {
        $op = $couch_db->remove_doc($doc);
      } else {
        $op = $couch_db->save_doc($doc);
      }
      $op->cb(sub{ CCNQ::AE::receive(@_); $rcv->end });
    });
  }

  return $rcv;
}

=head2 update_key_cv($server_uri,$db_name,\%params)

Modifies a single value in a hash field.

Returns a condvar which will return the values saved.

\%params contains:
  _id     The ID for the record to be updated.
  field   The field in the record that needs to be updated.
          This field must contain a hash.
  key     The key (in the field referenced above) which needs to be modified.
  value   The new value assigned to that key.

=cut

sub update_key_cv {
  my ($uri,$db_name,$params) = @_;
  debug("CCNQ::CouchDB::update_key_cv(".CCNQ::AE::ppp(@_).")");

  my $rcv = AE::cv;

  unless($params->{_id}) {
    id_required();
  }
  unless($params->{field}) {
    die 'field required';
  }
  unless($params->{key}) {
    die 'key required';
  }

  # Insert / Update a CouchDB record
  my $couch_db = db($uri,$db_name);

  $couch_db->open_doc($params->{_id})->cb(sub{
    my $doc = CCNQ::AE::receive(@_);

    if(!$doc) {
      $doc = {};
    }

    if(defined $params->{value}) {
      $doc->{$params->{field}}->{$params->{key}} = $params->{value};
    } else {
      delete $doc->{$params->{field}}->{$params->{key}};
    }

    $couch_db->save_doc($doc)->cb(sub{ CCNQ::AE::receive(@_); $rcv->send($doc) });
  });
  return $rcv;
}

=head2 delete_cv($server_uri,$db_name,\%params)

Returns a condvar which will return the content of the deleted record.

=cut

sub delete_cv {
  my ($uri,$db_name,$params) = @_;
  debug("CCNQ::CouchDB::delete_cv(".CCNQ::AE::ppp(@_).")");

  my $rcv = AE::cv;

  unless($params->{_id}) {
    id_required();
  }

  # Delete a CouchDB record
  my $couch_db = db($uri,$db_name);

  $couch_db->open_doc($params->{_id})->cb(sub{
    my $doc = CCNQ::AE::receive(@_);
    if(!$doc) {
      $rcv->send;
      return;
    }
    $couch_db->remove_doc($doc)->cb(sub{ CCNQ::AE::receive(@_); $rcv->send($doc) });
  });
  return $rcv;
}

sub retrieve_cv {
  my ($uri,$db_name,$params) = @_;
  debug("CCNQ::CouchDB::retrieve_cv(".CCNQ::AE::ppp(@_).")");

  my $rcv = AE::cv;

  unless($params->{_id}) {
    id_required();
  }

  # Return a CouchDB record, or a set of records
  my $couch_db = db($uri,$db_name);

  $couch_db->open_doc($params->{_id})->cb(sub{
    my $doc = CCNQ::AE::receive(@_);
    if(!$doc) {
      $rcv->send;
      return;
    }

    $rcv->send($doc);
    undef $doc;
  });
  return $rcv;
}

=head1 VIEWS

Views in CCNQ::CouchDB always return an array as key. This is used
so that we can return records that match a prefix.

=head2 view_cv($uri,$db_name,{ view => $view_name, _id => [key1,key2,..] })

Return a condvar which will return either undef or { rows => [ row1, row2, .. ] }
where row1, row2, .. are hashrefs of row records.

=cut

sub view_cv {
  my ($uri,$db_name,$params) = @_;
  debug("CCNQ::CouchDB::view_cv(".CCNQ::AE::ppp(@_).")");

  my $rcv = AE::cv;

  unless($params->{view}) {
    die 'View is required';
  }

  my $couch_db = db($uri,$db_name);

  my $view;
  if($params->{view} eq '_all_docs') {
    $view = $couch_db->all_docs();
  } else {
    unless($params->{_id} && ref($params->{_id}) eq 'ARRAY') {
      die 'ID is required and must be an array';
    }

    my @key_prefix = @{$params->{_id}};

    my $options = {
      startkey     => [@key_prefix],
      endkey       => [@key_prefix,{}],
      include_docs => "true",
    };

    $view = $couch_db->view($params->{view},$options);
  }

  $view->cb(sub{
    my $data = CCNQ::AE::receive(@_);
    $rcv->send($data);
    undef $data;
  });
  return $rcv;
}

'CCNQ::CouchDB';
