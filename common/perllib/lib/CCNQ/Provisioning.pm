package CCNQ::Provisioning;
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

use constant provisioning_db => 'provisioning';

use constant provisioning_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};

use AnyEvent;
use CCNQ::CouchDB;

sub install {
  return CCNQ::CouchDB::install(CCNQ::Provisioning::provisioning_db,provisioning_designs);
}

sub update {
  my ($params) = @_;
  return CCNQ::CouchDB::update_cv(provisioning_db,$params);
}

sub delete {
  my ($params) = @_;
  return CCNQ::CouchDB::delete_cv(provisioning_db,$params);
}

sub retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(provisioning_db,$params);
}

sub view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(provisioning_db,$params);
}

use AnyEvent::CouchDB;

sub lookup_plan {
  my ($account,$sub_account) = @_;
  my $id = join('/','sub_account',$account,$sub_account);
  my $rcv = AE::cv;
  couchdb(provisioning_db)->open_doc($id)->cb(sub{
    my $rec = eval { shift->recv };
    if($rec && $rec->{plan}) {
      load_plan($rec->{plan})->cb(sub{
        $rcv->send(eval {shift->recv});
      })
    } else {
      $rcv->send;
    }
  });
  return $rcv;
}

sub load_plan {
  my ($plan) = @_;
  my $id = join('/','plan',$plan);
  my $rcv = AE::cv;
  couchdb(provisioning_db)->open_doc($id)->cb(sub{
    my $rec = eval { shift->recv };
    $rcv->send(CCNQ::Rating::Plan->new($rec)) if $rec;
  });
  return $rcv;
}

1;
