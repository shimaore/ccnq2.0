package CCNQ::Actions::node::provisioning;
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

use CCNQ::AE;
use CCNQ::API;
use CCNQ::CouchDB;
use Logger::Syslog;

use constant provisioning_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};


sub install {
  my ($params,$context,$mcv) = @_;
  my $cv = CCNQ::CouchDB::install(CCNQ::API::provisioning_db,provisioning_designs,$mcv);
  $context->{condvar}->cb($cv);
}

sub update {
  my ($params,$context,$mcv) = @_;
  my $cv = CCNQ::CouchDB::update(CCNQ::API::provisioning_db,$params,$mcv);
  $context->{condvar}->cb($cv);
}

sub delete {
  my ($params,$context,$mcv) = @_;
  my $cv = CCNQ::CouchDB::delete(CCNQ::API::provisioning_db,$params,$mcv);
  $context->{condvar}->cb($cv);
}

sub retrieve {
  my ($params,$context,$mcv) = @_;
  my $cv = CCNQ::CouchDB::retrieve(CCNQ::API::provisioning_db,$params,$mcv);
  $context->{condvar}->cb($cv);
}

sub view {
  my ($params,$context,$mcv) = @_;
  my $cv = CCNQ::CouchDB::view(CCNQ::API::provisioning_db,$params,$mcv);
  $context->{condvar}->cb($cv);
}

'CCNQ::Actions::node::provisioning';
