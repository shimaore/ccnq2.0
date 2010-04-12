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

=pod
Note: in CCNQ::Portal::Inner::Provisioning we prepend the account ID,
      so most provisioning views will need to return the account ID as
      their first key.
=cut

sub view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(provisioning_uri,provisioning_db,$params);
}

=pod

This document specifies minimum record layout for data stored in the
provisioning database.

Generally speaking, records in the provisioning database should contain
full requests as received by the application's business logic.

Note: The manager/request associated with base CCNQ::Proxy::$action will eventually disappear since they are redundant.

** Records

The following fields are common (so that we can build views):

  _id: $profile/$$profile
  account: $account_id
  account_sub: $account_sub_id
  type: $request_type
    indicates that this record can be re-submitted via manager-request "$type".
    (auto-populated by node/api)
  profile: $profile
    one of "number", "endpoint", "location"
  $profile: $id
    for $profile "number", $id should be a full qualified phone number (E.164 without "+" sign)
    for $profile "endpoint", $id should be a unique endpoint identifier
    for $profile "location", $id should be a unique location identifier (e.g. main number)

* "number" profile:

  Allows to re-create the complete routing (in & out) for a given number.
  Includes mapping the number to a customer endpoint.

* "endpoint" profile:

  Allows to re-create a customer endpoint.
  Including mapping it to location information.

* "location" profile:

  Provides information about a customer location, used especially for emergency location.

** Views

The node/api interface (for access to provisioning views) prepends the $account_id to
the list of parameters for the view. Therefor most views (and all views used by the node/api
"/provisioning" interface) will return keys that start with the $account_id.
(This is done so that the portal behavior, which asks to select an account for most operations,
is consistent.)

=cut

1;
