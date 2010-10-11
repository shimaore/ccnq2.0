package CCNQ::Billing::Table;
# Copyright (C) 2010  Stephane Alnet
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

use CCNQ::Rating::Table;
use AnyEvent;
use AnyEvent::CouchDB;
use CCNQ::AE;

sub _db_name { return "table_".$_[0] }

sub create {
  my ($params) = @_;
  my $rcv = AE::cv;
  my $table = CCNQ::Rating::Table->new(_db_name($params->{name}));
  $table->db->create()->cb(sub{
    CCNQ::CouchDB::receive_ok($rcv,@_);
  });
  return $rcv;
}

sub all_tables {
  my $rcv = AE::cv;
  my $couch = couch(CCNQ::Billing::billing_uri);
  $couch->all_dbs->cb(sub{
    my $dbs = CCNQ::AE::receive(@_);
    my @dbs = map { /^table_(.*)$/; $1 } grep { /^table_/ } @$dbs;
    $rcv->send( $dbs && [ @dbs ]);
  });
  return $rcv;
}

use CCNQ::Billing;

sub all_prefixes {
  my ($params) = @_;
  my $name       = delete $params->{name};
  return CCNQ::CouchDB::view_cv(CCNQ::Billing::billing_uri,_db_name($name),{ view => '_all_docs' });
}

sub retrieve_prefix {
  my ($params) = @_;
  my $name       = delete $params->{name};
  $params->{_id} = delete $params->{prefix};
  return CCNQ::CouchDB::retrieve_cv(CCNQ::Billing::billing_uri,_db_name($name),$params);
}

sub update_prefix {
  my ($params) = @_;
  my $name       = delete $params->{name};
  $params->{_id} = delete $params->{prefix};
  return CCNQ::CouchDB::update_cv(CCNQ::Billing::billing_uri,_db_name($name),$params);
}

sub update_prefix_bulk {
  my ($params) = @_;
  my $name       = delete $params->{name};
  return CCNQ::CouchDB::update_bulk_cv(CCNQ::Billing::billing_uri,_db_name($name),$params);
}

sub delete_prefix {
  my ($params) = @_;
  my $name       = delete $params->{name};
  $params->{_id} = delete $params->{prefix};
  return CCNQ::CouchDB::delete_cv(CCNQ::Billing::billing_uri,_db_name($name),$params);
}

'CCNQ::Billing::Table';
