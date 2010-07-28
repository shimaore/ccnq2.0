package CCNQ::CouchDB;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
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

sub install {
  my ($uri,$db_name,$designs) = @_;
  $designs ||= {};

  my $rcv = AE::cv;

  info("Creating CouchDB '${db_name}' database on server $uri");
  my $couch = couch($uri);
  my $db = $couch->db($db_name);

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
  my $couch = couch($uri);
  my $couch_db = $couch->db($db_name);

  use Logger::Syslog; use CCNQ::AE;
  $couch_db->open_doc($params->{_id})->cb(sub{
    my $doc = CCNQ::AE::receive(@_);
    if($doc) {
      # If the record exists, only updates the specified fields.
      for my $key (grep { !/^(_id|_rev)$/ } keys %{$params}) {
        $doc->{$key} = $params->{$key};
      }
      debug("CCNQ::CouchDB::update_cv: updating document");
      $couch_db->save_doc($doc)->cb(sub{ CCNQ::AE::receive(@_); $rcv->send($doc) });
    } else {
      # Assume missing document
      debug("CCNQ::CouchDB::update_cv: creating document");
      $couch_db->save_doc($params)->cb(sub{ CCNQ::AE::receive(@_); $rcv->send($params) });
    }
  });
  return $rcv;
}

=head2 update_key_cv($server_uri,$db_name,\%params)

Returns a condvar which will return the values saved.

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
  my $couch = couch($uri);
  my $couch_db = $couch->db($db_name);

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
  my $couch = couch($uri);
  my $couch_db = $couch->db($db_name);

  $couch_db->open_doc($params->{_id})->cb(sub{
    my $doc = CCNQ::AE::receive(@_);
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
  my $couch = couch($uri);
  my $couch_db = $couch->db($db_name);
  $couch_db->open_doc($params->{_id})->cb(sub{
    my $doc = CCNQ::AE::receive(@_);
    if(!$doc) {
      $rcv->send;
      return;
    }

    $rcv->send($doc);
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

  my $couch = couch($uri);
  my $couch_db = $couch->db($db_name);

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

    debug("view_cv: ".
      join(',', map {
          join(' ', map { sprintf("%04x",$_) } unpack("U*",$_));
        } @key_prefix )
    );

    $view = $couch_db->view($params->{view},$options);
  }

  $view->cb(sub{
    my $data = CCNQ::AE::receive(@_);
    $rcv->send($data);
  });
  return $rcv;
}

'CCNQ::CouchDB';
