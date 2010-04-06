package CCNQ::Billing::Table;
# Copyright (C) 2010  Stephane Alnet
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

use CCNQ::Rating::Table;

sub create {
  my ($params) = @_;
  my $rcv = AE::cv;
  my $db = CCNQ::Rating::Table->new($params->{name});
  $db->create()->cb(sub{
    CCNQ::CouchDB::receive_ok(@_,$rcv);
  });
  return $rcv;
}

sub update_prefix {
  my ($params) = @_;
  my $name       = delete $params->{name};
  $params->{_id} = delete $params->{prefix};
  return CCNQ::CouchDB::update_cv(billing_uri,$name,$params);
}

sub delete_prefix {
  my ($params) = @_;
  my $name       = delete $params->{name};
  $params->{_id} = delete $params->{prefix};
  return CCNQ::CouchDB::delete_cv(billing_uri,$name,$params);
}

'CCNQ::Billing::Table';
