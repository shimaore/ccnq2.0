package CCNQ::CDR;
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

use CCNQ::Install;

# Normally only one server should be part of this cluster (until we
# implementing sharding of the CDR db).
use constant CDR_CLUSTER_NAME => 'cdr';
use constant::defer cdr_cluster_jid => sub {
  CCNQ::Install::make_muc_jid(CDR_CLUSTER_NAME)
};

use AnyEvent;
use AnyEvent::CouchDB;
use CCNQ::CouchDB;

use constant::defer cdr_uri => sub {
  CCNQ::Install::make_couchdb_uri_from_server(CCNQ::Install::cluster_fqdn('cdr'))
};
use constant cdr_db => 'cdr';

use constant cdr_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};

sub db { CCNQ::CouchDB::db(cdr_uri,cdr_db) }

sub install {
  my ($params,$context) = @_;
  return CCNQ::CouchDB::install(cdr_uri,cdr_db,cdr_designs);
}

sub insert {
  my ($params) = @_;
  return CCNQ::CouchDB::update_cv(cdr_uri,cdr_db,$params);
}

sub retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(cdr_uri,cdr_db,$params);
}

sub period {
  my ($account,$year,$month,$day) = @_;

  $day = int($day);
  my ($start_key,$end_key);
  if($day) {
    $start_key = sprintf('%s-%04d%02d%02d',$account,$year,$month,$day);
    $end_key   = $start_key.chr(0x7e);
  } else {
    $start_key = sprintf('%s-%04d%02d00',$account,$year,$month);
    $end_key   = sprintf('%s-%04d%02d32',$account,$year,$month);
  }

  return db->all_docs({
    startkey => $start_key,
    endkey   => $end_key,
    include_docs => 'true',
  });
}

'CCNQ::CDR';
