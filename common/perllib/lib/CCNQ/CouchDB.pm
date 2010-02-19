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

use Logger::Syslog;
use AnyEvent::CouchDB;
use CCNQ::AE;

sub pp {
  my $v = shift;
  return qq(nil)  if !defined($v);
  return qq("$v") if !ref($v);
  return '[ '.join(', ', map { pp($_) } @{$v}).' ]' if ref($v) eq 'ARRAY' ;
  return '{ '.join(', ', map { qq("$_": ).pp($v->{$_}) } sort keys %{$v}).' }'
    if ref($v) eq 'HASH';
  return qq("$v");
}

sub receive {
  my $result;
  eval { $result = $_[0]->recv };
  if($@) {
    error("CouchDB failed: ".pp($@).", with result ".pp($result));
    return undef;
  }

  debug("CouchDB: received ".pp($result));
  return $result;
}

sub receive_mcv {
  my $mcv = shift;
  return sub {
    $mcv->send( receive(@_) ? CCNQ::AE::SUCCESS() : CCNQ::AE::FAILURE() );
  };
}

sub install {
  my ($db_name,$designs,$mcv) = @_;
  $designs ||= {};

  info("Creating CouchDB '${db_name}' database");
  my $couch = couch;
  my $db = $couch->db($db_name);

  my $install_designs = sub {
    while( my ($design_name,$design_content) = each %{$designs} ) {
      my $id = "_design/${design_name}";

      $design_content->{_id} = $id;
      $design_content->{language} ||= 'javascript';
      # $design_content->{views} should be specified

      info("Open old document $id");
      $db->open_doc($id)->cb(sub{
        my $old_doc = receive(@_);
        if($old_doc) {
          $design_content->{_rev} = $old_doc->{_rev};
        }
        info("Create new document $id");
        # XXX? receive_mcv() here might prevent all of the designs from being installed if there is more than one
        $db->save_doc($design_content)->cb(receive_mcv($mcv));
      });
    }
  };

  my $cv = $db->info();
  $cv->cb(sub{
    info("Info for CouchDB '${db_name}' database");
    if(!receive(@_)) {
      $db->create()->cb(sub{
        info("Created CouchDB '${db_name}' database");
        if(receive(@_)) {
          $install_designs->();
        } else {
          $mcv->send(CCNQ::AE::FAILURE());
        }
      });
    } else {
      $install_designs->();
    }
  });
  return $cv;
}

=head1 UPDATE

Updates in CCNQ::CouchDB are used to update a set of fields in an
existing record, or to create a new record (if the record key is not found).
Fields not specified in the parameters are left as they were in the existing
record.

This is different from the usual PUT semantics. To obtain proper PUT
semantics, do a delete() then an update().

=cut

sub update {
  my ($db_name,$params,$mcv) = @_;

  unless($params->{_id}) {
    return $mcv->send(CCNQ::AE::FAILURE('ID is required'));
  }

  # Insert / Update a CouchDB record
  my $couch_db = couchdb($db_name);

  my $cv = $couch_db->open_doc($params->{_id});

  $cv->cb(sub{
    my $doc;
    $doc = receive(@_);
    if($doc) {
      # If the record exists, only updates the specified fields.
      for my $key (grep { !/^(_id|_rev)$/ } keys %{$params}) {
        $doc->{$key} = $params->{$key};
      }
      $couch_db->save_doc($doc)->cb(receive_mcv($mcv));
    } else {
      # Assume missing document
      $couch_db->save_doc($params)->cb(receive_mcv($mcv));
    }
  });
  return $cv;
}

sub delete {
  my ($db_name,$params,$mcv) = @_;

  unless($params->{_id}) {
    return $mcv->send(CCNQ::AE::FAILURE('ID is required'));
  }
  # Delete a CouchDB record
  my $couch_db = couchdb($db_name);
  my $cv = $couch_db->open_doc($params->{_id});
  $cv->cb(sub{
    my $doc = receive(@_);
    $couch_db->remove_doc($doc)->cb(receive_mcv($mcv));
  });
  return $cv;
}

sub retrieve {
  my ($db_name,$params,$mcv) = @_;

  unless($params->{_id}) {
    return $mcv->send(CCNQ::AE::FAILURE('ID is required'));
  }
  # Return a CouchDB record, or a set of records
  my $couch_db = couchdb($db_name);
  my $cv = $couch_db->open_doc($params->{_id});
  $cv->cb(sub{
    my $doc = receive(@_);
    if($doc) {
      $mcv->send(CCNQ::AE::SUCCESS($doc));
    } else {
      $mcv->send(CCNQ::AE::FAILURE);
    }
  });
  return $cv;
}

=head1 VIEWS

Views in CCNQ::CouchDB always return an array as key. This is used
so that we can return records that match a prefix.

=cut

sub view {
  my ($db_name,$params,$mcv) = @_;

  unless($params->{view}) {
    return $mcv->send(CCNQ::AE::FAILURE('View is required'));
  }
  unless($params->{_id} && ref($params->{_id}) eq 'ARRAY') {
    return $mcv->send(CCNQ::AE::FAILURE('Key is required and must be an array'));
  }
  my @key_prefix = @{$params->{_id}};

  # Return a CouchDB record, or a set of records
  my $couch_db = couchdb($db_name);
  my $cv = $couch_db->view(
    $params->{view},
    {
      startkey => [@key_prefix],
      endkey   => [@key_prefix,{}],
      include_docs => "true",
      error    => sub {
        $mcv->send(CCNQ::AE::FAILURE);
      }
    }
  );
  $cv->cb(sub{
    my $view = receive(@_);
    if(!$view) {
      debug("Document ".join(',',@key_prefix)." not found.");
      $mcv->send(CCNQ::AE::FAILURE("Not found."));
      return;
    }

    $mcv->send(CCNQ::AE::SUCCESS({rows => $view->{rows}}));
  });
  return $cv;
}

'CCNQ::CouchDB';
