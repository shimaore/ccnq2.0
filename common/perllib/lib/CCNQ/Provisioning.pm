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

use CCNQ::Install;
use constant::defer provisioning_uri => sub {
  CCNQ::Install::couchdb_local_uri;
};
use constant provisioning_db => 'provisioning';

use constant js_report_by_account => <<'JAVASCRIPT';
  function (doc) {
    emit([doc.account,doc.account_sub,doc.type,doc._id],null);
  }
JAVASCRIPT

use constant js_report_numbers => <<'JAVASCRIPT';
  function (doc){
    if(doc.type == 'number') {
      emit([doc.account,doc.number])
    }
  }
JAVASCRIPT

use constant js_report_endpoints => <<'JAVASCRIPT';
  function (doc){
    if(doc.type == 'endpoint') {
      emit([doc.account,doc.endpoint])
    }
  }
JAVASCRIPT

use constant js_report_locations => <<'JAVASCRIPT';
  function (doc){
    if(doc.type == 'location') {
      emit([doc.account,doc.location])
    }
  }
JAVASCRIPT


use constant provisioning_designs => {
  report => {
    language => 'javascript',
    views    => {
      account => {
        map => js_report_by_account,
        # no reduce function
      },
      numbers => {
        map => js_report_numbers,
        # no reduce function
      },
      endpoints => {
        map => js_report_endpoints,
        # no reduce function
      },
      locations => {
        map => js_report_locations,
        # no reduce function
      },
    },
  },
};

use CCNQ::AE;
use CCNQ::CouchDB;

sub install {
  return CCNQ::CouchDB::install(provisioning_uri, provisioning_db, provisioning_designs);
}

sub update {
  my ($params) = @_;
  return CCNQ::AE::croak_cv("No type specified") unless exists $params->{type};
  return CCNQ::CouchDB::update_cv(provisioning_uri,provisioning_db,$params);
}

sub delete {
  my ($params) = @_;
  return CCNQ::CouchDB::delete_cv(provisioning_uri,provisioning_db,$params);
}

sub retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(provisioning_uri,provisioning_db,$params);
}

sub view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(provisioning_uri,provisioning_db,$params);
}

1;
