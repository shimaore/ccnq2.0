package CCNQ::Billing;
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

use CCNQ::Install;

use constant::defer billing_uri => sub {
  CCNQ::Install::couchdb_local_uri;
};
use constant billing_db => 'billing';

use constant billing_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};

use CCNQ::CouchDB;

sub install {
  return CCNQ::CouchDB::install(billing_uri,billing_db,billing_designs);
}

sub billing_update {
  my ($params) = @_;
  return CCNQ::CouchDB::update_cv(billing_uri,billing_db,$params);
}

sub billing_update_key {
  my ($params) = @_;
  return CCNQ::CouchDB::update_key_cv(billing_uri,billing_db,$params);
}

sub billing_delete {
  my ($params) = @_;
  return CCNQ::CouchDB::delete_cv(billing_uri,billing_db,$params);
}

sub billing_retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(billing_uri,billing_db,$params);
}

sub billing_view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(billing_uri,billing_db,$params);
}

'CCNQ::Billing';
