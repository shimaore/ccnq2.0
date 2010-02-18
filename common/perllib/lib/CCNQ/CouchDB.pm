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

sub recv {
  my $cb = shift;
  my $result;
  eval { $result = $cb->recv };
  if($@) {
    error("CouchDB: ".CCNQ::Portal::Formatter::pp($@));
    return undef;
  } else {
    debug("CouchDB: received ".CCNQ::Portal::Formatter::pp($result));
    return $result;
  }
}

sub recv_mcv {
  my $mcv = shift;
  return sub {
    $mcv->send( recv(@_) ? CCNQ::AE::SUCCESS : CCNQ::AE::FAILURE );
  }
}

sub install {
  my ($db_name,$designs,$mcv) = @_;
  $designs ||= {};

  info("Creating CouchDB '${db_name}' database");
  my $couch = couch;
  my $db = $couch->db($db_name);
  my $cv = $db->info();

  $cv->cb(sub{
    if(!recv(@_)) {
      $db->create()->cb(sub{
        recv(@_);
        info("Created CouchDB '${db_name}' database");
      });
    }

    while( my ($design_name,$design_content) = each %{$designs} ) {
      my $id = "_design/${design_name}";

      # Remove old document
      $db->open_doc($id)->cb(sub{
        my $old_doc = recv(@_);
        if($old_doc) {
          $db->remove_doc($old_doc)->cb(sub{
            recv(@_);
          });
        }
      });

      # Create new document
      $design_content->{_id} = $id;
      $design_content->{language} ||= 'javascript';
      # $design_content->{views} should be specified

      $db->save_doc($design_content)->cb(recv_mcv($mcv));
    }

  });
  return $cv;
}

sub update {
  my ($db_name,$params,$mcv) = @_;

  unless($params->{_id}) {
    return $mcv->send(CCNQ::AE::FAILURE('ID is required'));
  }

  # Insert / Update a CouchDB record
  my $couch_db = couchdb($db_name);

  my $cv = $couch_db->open_doc($params->{_id});

  # XXX Implement proper CouchDB semantics.
  $cv->cb(sub{
    my $doc;
    $doc = recv(@_);
    if($doc) {
      # If the record exists, only updates the specified fields.
      for my $key (grep { !/^(_id|_rev)$/ } keys %{$params}) {
        $doc->{$key} = $params->{$key};
      }
      $couch_db->save_doc($doc)->cb(recv_mcv($mcv));
    } else {
      # Assume missing document
      $couch_db->save_doc($params)->cb(recv_mcv($mcv));
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
    my $doc = recv(@_);
    $couch_db->remove_doc($doc)->cb(recv_mcv($mcv));
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
    my $doc = recv(@_);
    if($doc) {
      $mcv->send(CCNQ::AE::SUCCESS($doc));
    } else {
      $mcv->send(CCNQ::AE::FAILURE);
    }
  });
  return $cv;
}

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
    my $view = recv(@_);
    if(!$view) {
      debug("Document $params->{_id} not found.");
      $mcv->send(CCNQ::AE::FAILURE("Not found."));
      return;
    }

    $mcv->send(CCNQ::AE::SUCCESS({rows => $view->{rows}}));
  });
  return $cv;
}

'CCNQ::CouchDB';
