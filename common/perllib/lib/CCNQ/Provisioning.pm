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

use CCNQ::CouchDB;

sub update {
  my ($params,$mcv) = @_;
  return CCNQ::CouchDB::update(provisioning_db,$params,$mcv);
}

sub delete {
  my ($params,$mcv) = @_;
  return CCNQ::CouchDB::delete(provisioning_db,$params,$mcv);
}

sub retrieve {
  my ($params,$mcv) = @_;
  return CCNQ::CouchDB::retrieve(provisioning_db,$params,$mcv);
}

sub view {
  my ($params,$mcv) = @_;
  return CCNQ::CouchDB::view(provisioning_db,$params,$mcv);
}

sub lookup_plan {
  my ($account,$sub_account) = @_;
  my $mcv = AnyEvent->condvar;
  retrieve({
    _id => join('/','sub_account',$account,$sub_account),
  },$mcv)->recv();
  my $plan = $mcv->recv()->{result};
}

use constant provisioning_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};

sub install {
  my ($mcv) = @_;
  return CCNQ::CouchDB::install(CCNQ::Provisioning::provisioning_db,provisioning_designs,$mcv);
}


1;
