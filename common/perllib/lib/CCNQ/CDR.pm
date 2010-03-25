package CCNQ::CDR;
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

use AnyEvent;
use CCNQ::CouchDB;

use constant cdr_server => 'http://'.CCNQ::Install::cluster_fqdn('cdr').'/';
use constant cdr_db => 'cdr';

use constant cdr_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};


sub install {
  my ($params,$context) = @_;
  return CCNQ::CouchDB::install(cdr_server,cdr_db,cdr_designs);
}

sub insert {
  my ($rated_cbef) = @_;
  $rated_cbef->cleanup;
  my $rcv = AE::cv;
  couch(cdr_server)->db(cdr_db)->save_doc($rated_cbef)->cb(sub{
    CCNQ::CouchDB::receive_ok(shift,$rcv);
  });
  return $rcv;
}

sub retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(cdr_server,cdr_db,$params);
}

sub view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(cdr_server,cdr_db,$params);
}

'CCNQ::CDR';
