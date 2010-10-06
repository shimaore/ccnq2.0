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

# All records related to a given account.
use constant js_report_by_type => <<'JAVASCRIPT';
  function (doc) {
    var year  = doc.start_date.substr(0,4);
    var month = doc.start_date.substr(4,2);
    var day   = doc.start_date.substr(6,2);
    var hour  = doc.start_time.substr(0,2);
    var minu  = doc.start_time.substr(2,2);
    var seco  = doc.start_time.substr(4,2);
    emit([doc.account,doc.account_sub,doc.event_type,year,month,day,hour,minu,seco],null);
  }
JAVASCRIPT

use constant js_report_invoicing => <<'JAVASCRIPT';
  function (doc) {
    emit([doc.account,doc.start_date,doc.account_sub,doc.event_type],null);
  }
JAVASCRIPT

use constant js_report_monthly_by_sub => <<'JAVASCRIPT';
  function (doc) {
    var year  = doc.start_date.substr(0,4);
    var month = doc.start_date.substr(4,2);
    emit([doc.account,year,month,doc.account_sub,doc.event_type,day,hour,minu,seco],null);
  }
JAVASCRIPT

use constant cdr_designs => {
  report => {
    language => 'javascript',
    views    => {
      by_type => {
        map => js_report_by_type,
      },
      invoicing => {
        map => js_report_invoicing,
      },
      monthly_by_sub => {
        map => js_report_monthly_by_sub,
      }
    },
  },
};


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

sub view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(cdr_uri,cdr_db,$params);
}

'CCNQ::CDR';
