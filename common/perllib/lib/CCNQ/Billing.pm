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

# This is a "virtual cluster name" -- no such cluster is defined in
# the (DNS) configuration, but the MUC room is used as a rendez-vous
# point to propagate the data.
use constant BILLING_CLUSTER_NAME => 'billing';
use constant::defer billing_cluster_jid => sub {
  CCNQ::Install::make_muc_jid(BILLING_CLUSTER_NAME)
};

use constant::defer billing_uri => sub {
  CCNQ::Install::couchdb_local_uri;
};
use constant billing_db => 'billing';

# All records related to a given account.
use constant js_report_account_all => <<'JAVASCRIPT';
  function (doc) {
    if(doc.account) {
      emit([doc.account],null);
    }
    if(doc.billing_accounts) {
      for(var account in doc.billing_accounts) {
        emit([account],null);
      }
    }
  }
JAVASCRIPT

# All "account"-class documents.
use constant js_report_accounts => <<'JAVASCRIPT';
  function (doc) {
    if(doc.profile == 'account') {
      emit([doc.account],null);
    }
  }
JAVASCRIPT

# All records related to a given account_sub.
use constant js_report_account_sub_all => <<'JAVASCRIPT';
  function (doc) {
    if(doc.account_sub) {
      emit([doc.account,doc.account_sub],null);
    }
  }
JAVASCRIPT

# All "account_sub"-class documents.
use constant js_report_account_subs => <<'JAVASCRIPT';
function (doc) {
  if(doc.profile == 'account_sub') {
    emit([doc.account,doc.account_sub],null);
  }
}
JAVASCRIPT

# All "plan"-class documents.
use constant js_report_plans => <<'JAVASCRIPT';
function (doc) {
  if(doc.profile == 'plan') {
    emit([doc.name],null);
  }
}
JAVASCRIPT

# All "user"-class documents.
use constant js_report_users => <<'JAVASCRIPT';
  function (doc) {
    if(doc.profile == 'user') {
      emit([doc.user_id],null);
    }
  }
JAVASCRIPT

use constant billing_designs => {
  report => {
    language => 'javascript',
    views    => {
      account_all => {
        map => js_report_account_all,
      },
      accounts => {
        map => js_report_accounts,
      },
      account_sub_all => {
        map => js_report_account_sub_all,
      },
      account_subs => {
        map => js_report_account_subs,
      },
      plans => {
        map => js_report_plans,
      },
      users => {
        map => js_report_users,
      }
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
