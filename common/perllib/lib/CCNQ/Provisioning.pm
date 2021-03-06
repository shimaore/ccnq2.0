package CCNQ::Provisioning;
# Copyright (C) 2009  Stephane Alnet
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

# This is a "virtual cluster name" -- no such cluster is defined in
# the (DNS) configuration, but the MUC room is used as a rendez-vous
# point to propagate the data.
use constant PROVISIONING_CLUSTER_NAME => 'provisioning';
use constant::defer provisioning_cluster_jid => sub {
  CCNQ::Install::make_muc_jid(PROVISIONING_CLUSTER_NAME)
};

use constant::defer provisioning_uri => sub {
  CCNQ::Install::couchdb_local_uri;
};
use constant provisioning_db => 'provisioning';

sub db { CCNQ::CouchDB::db(provisioning_uri,provisioning_db) }

use constant js_report_by_account => <<'JAVASCRIPT';
  function (doc) {
    emit([doc.account,doc.account_sub,doc.profile,doc.type,doc._id],null);
  }
JAVASCRIPT

use constant js_report_numbers => <<'JAVASCRIPT';
  function (doc){
    if(doc.profile == 'number') {
      emit([doc.account,doc.number],null)
    }
  }
JAVASCRIPT

use constant js_report_endpoints => <<'JAVASCRIPT';
  function (doc){
    if(doc.profile == 'endpoint') {
      emit([doc.account,doc.endpoint],null)
    }
  }
JAVASCRIPT

use constant js_report_locations => <<'JAVASCRIPT';
  function (doc){
    if(doc.profile == 'location') {
      emit([doc.account,doc.location],null)
    }
  }
JAVASCRIPT

use constant js_report_lookup_number => <<'JAVASCRIPT';
  function (doc){
    if(doc.profile == 'number') {
      emit([doc.number],null)
    }
  }
JAVASCRIPT

use constant js_report_lookup_number_in_account => <<'JAVASCRIPT';
  function (doc){
    if(doc.profile == 'number') {
      emit([doc.account,doc.number],null)
    }
  }
JAVASCRIPT

use constant js_report_count => <<'JAVASCRIPT';
  function (doc){
    if(doc.account && doc.account_sub) {
      emit([doc.account,doc.account_sub,doc.profile,doc.type],1);
    }
  }
JAVASCRIPT

use constant js_reduce_sum => '_sum';

# Numbers bank: Make sure the selection criteria match those in
# CCNQ::Activities::Number.

use constant js_number_bank => <<'JAVASCRIPT';
  function (doc){
    if(doc.profile == "number" && !doc.endpoint && !doc.account) {
      emit([doc.number],null);
    }
  }
JAVASCRIPT

use constant js_number_bank_by_type => <<'JAVASCRIPT';
  function (doc){
    if(doc.profile == "number" && !doc.endpoint && !doc.account && doc.number_type) {
      emit([doc.number_type,doc.number],null);
    }
  }
JAVASCRIPT

# Locate endpoint across all accounts
use constant js_report_lookup_endpoint => <<'JAVASCRIPT';
  function (doc) {
    if(doc.profile != 'endpoint') return;
    emit([doc.endpoint],null);
    if(doc.ip ) emit([doc.ip ],null);
    if(doc.srv) emit([doc.srv],null);
  }
JAVASCRIPT

# TBD: locate endpoint across all accounts in an account context

# Locate endpoint in an account
use constant js_report_lookup_endpoint_in_account => <<'JAVASCRIPT';
  function (doc) {
    if(doc.profile != 'endpoint') return;
    emit([doc.account,doc.endpoint],null);
    if(doc.ip ) emit([doc.account,doc.ip ],null);
    if(doc.srv) emit([doc.account,doc.srv],null);
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
      number => {
        map => js_report_numbers,
        # no reduce function
      },
      endpoint => {
        map => js_report_endpoints,
        # no reduce function
      },
      location => {
        map => js_report_locations,
        # no reduce function
      },
      lookup_number => {
        map => js_report_lookup_number,
        # no reduce function
      },
      lookup_number_in_account => {
        map => js_report_lookup_number_in_account,
      },
      count => {
        map => js_report_count,
        reduce => js_reduce_sum,
      },
      number_bank => {
        map => js_number_bank,
        # no reduce function
      },
      number_bank_by_type => {
        map => js_number_bank_by_type,
        # no reduce function
      },
      lookup_endpoint => {
        map => js_report_lookup_endpoint,
      },
      lookup_endpoint_in_account => {
        map => js_report_lookup_endpoint_in_account,
      },
    },
  },
};

use CCNQ::AE;
use CCNQ::CouchDB;

sub install {
  return CCNQ::CouchDB::install(provisioning_uri, provisioning_db, provisioning_designs);
}

sub provisioning_update {
  my ($params) = @_;
  exists($params->{type}) or
    return CCNQ::AE::croak_cv("No type specified in ".CCNQ::AE::pp($params));
  return CCNQ::CouchDB::update_cv(provisioning_uri,provisioning_db,$params);
}

sub provisioning_delete {
  my ($params) = @_;
  return CCNQ::CouchDB::delete_cv(provisioning_uri,provisioning_db,$params);
}

sub provisioning_retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(provisioning_uri,provisioning_db,$params);
}

=pod
Note: in CCNQ::Portal::Inner::Provisioning we prepend the account ID,
      so most provisioning views will need to return the account ID as
      their first key.
=cut

sub provisioning_view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(provisioning_uri,provisioning_db,$params);
}

sub provisioning_paginate {
  my ($view,$account,$skip,$limit) = @_;

  return db->view($view,{
    include_docs  => 'true',
    startkey      => [$account],
    endkey        => [$account,{}],
    skip          => $skip,
    limit         => $limit,
  });
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
