# billing/actions.pm

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

use CCNQ::AE;
use CCNQ::API;
use AnyEvent::CouchDB;

{
  install => sub {
    $mcv->send(CCNQ::AE::SUCCESS);
  },

  update => sub {
    my ($params,$context,$mcv) = @_;
    # Insert / Update a CouchDB record
    # If the record exists, only updates the specified fields.
    my $couch_db = couchdb(CCNQ::API::provisioning_db);

    my $cv = $couch_db->open_doc($params->{_id});
    $cv->cb(sub{
      eval { my $doc = $_[0]->recv; }
      if($@) {
        # Assume missing document
        $couch_db->save_doc($params)->cb(sub{
          eval { $_[0]->recv; }
          if($@) {
            $mcv->send(CCNQ::AE::FAILURE($@));
          } else {
            $mcv->send(CCNQ::AE::SUCCESS);
          }
        });
      } else {
        for my $key (grep !/^(_id|_rev)$/ keys %params) {
          $doc->{$key} = $params->{$key};
        }
        $couch_db->save_doc($doc)->cb(sub{
          eval { $_[0]->recv; }
          if($@) {
            $mcv->send(CCNQ::AE::FAILURE($@));
          } else {
            $mcv->send(CCNQ::AE::SUCCESS);
          }
        });
      }
    });
  },

  delete => sub {
    my ($params,$context,$mcv) = @_;
    # Delete a CouchDB record
    my $couch_db = couchdb(CCNQ::API::provisioning_db);
    my $cv = $couch_db->open_doc($params->{_id});
    $cv->cb(sub{
      eval { my $doc = $_[0]->recv; }
      $couch_db->remove_doc($doc)->cb(sub{
        eval { $_[0]->recv; }
        if($@) {
          $mcv->send(CCNQ::AE::FAILURE($@));
        } else {
          $mcv->send(CCNQ::AE::SUCCESS);
        }
      });
    });
  },

  retrieve => sub {
    my ($params,$context,$mcv) = @_;
    # Return a CouchDB record, or a set of records
    my $couch_db = couchdb(CCNQ::API::provisioning_db);
    my $cv = $couch_db->open_doc($params->{_id});
    $cv->cb(sub{
      eval { my $doc = $_[0]->recv; }
      if($@) {
        $mcv->send(CCNQ::AE::FAILURE($@));
      } else {
        $mcv->send(CCNQ::AE::SUCCESS($doc));
      }
    });
  },

}
