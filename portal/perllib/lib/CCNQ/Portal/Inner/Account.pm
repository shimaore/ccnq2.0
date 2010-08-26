package CCNQ::Portal::Inner::Account;
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

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;

use CCNQ::AE;
use CCNQ::API;

use CCNQ::Portal::Inner::Util;

sub gather_field {
  my $account = session('account');

  var portal_users  => \&CCNQ::Portal::Inner::Util::portal_users;
  var billing_users => \&CCNQ::Portal::Inner::Util::billing_users;
  var account_subs  => \&CCNQ::Portal::Inner::Util::account_subs;
  var get_plans     => \&CCNQ::Portal::Inner::Util::get_plans;

  my $account_billing_data = CCNQ::Portal::Inner::Util::account_billing_data($account);

  var field => {
    %$account_billing_data,
    account => $account,
  };
}

sub gather_field_sub {
  my $account = session('account');
  my $account_sub = shift;

  var get_plans     => \&CCNQ::Portal::Inner::Util::get_plans;

  my $account_sub_billing_data = CCNQ::Portal::Inner::Util::account_sub_data($account,$account_sub) || {};

  var field => {
    %$account_sub_billing_data,
    account => $account,
    account_sub => $account_sub,
  };
}

get '/billing/account' => sub {
  var template_name => 'api/account';
  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  if( session('account') && session('account') =~ /^[\w-]+$/ ) {
    gather_field();
  }
  return CCNQ::Portal::content;
};

post '/billing/account' => sub {
  var template_name => 'api/account';
  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  # This is how we create new accounts.
  if(params->{account} && params->{account} =~ /^[\w-]+$/) {
       session account => params->{account};
  }
  session('account') &&
  session('account') =~ /^[\w-]+$/
    or return CCNQ::Portal::content( error => _('Please use a valid account number')_ );

  my $params = CCNQ::Portal::Util::neat({
    account => session('account')
  },qw(
    name
    billing_country
    billing_cycle
  ));

  int($params->{billing_cycle}) &&
  $params->{billing_cycle} >= 1 &&
  $params->{billing_cycle} <= 28
    or return CCNQ::Portal::content( error => _('Billing cycle must be between 1 and 28')_ );

  $params->{billing_cycle} = int($params->{billing_cycle});

  # Update the information in the portal.
  # N/A -- no native account-related information is stored in the portal.
  # ("portal_accounts" is a property of the portal user.)

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update('account',$params,$cv1);
  return CCNQ::Portal::Util::redirect_request($cv1);
};

get '/billing/account_sub/:account_sub' => sub {
  var template_name => 'api/account_sub';

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  session('account') &&
  session('account') =~ /^[\w-]+$/
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  params->{account_sub} &&
  params->{account_sub} =~ /^[\w-]+$/
    or return CCNQ::Portal::content( error => _('Please enter a valid account_sub number')_ );

  my $account_sub = params->{account_sub};

  gather_field_sub($account_sub);

  return CCNQ::Portal::content;
};

get '/billing/account_sub' => sub {
  var template_name => 'api/account_sub';

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  session('account') &&
  session('account') =~ /^[\w-]+$/
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  if( params->{account_sub} && params->{account_sub} =~ /^[\w-]+$/ ) {
    gather_field_sub(params->{account_sub});
  } else {
    var get_plans      => \&CCNQ::Portal::Inner::Util::get_plans;
  }

  return CCNQ::Portal::content;
};

sub handle_account_sub {
  var template_name => 'api/account_sub';

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  session('account') &&
  session('account') =~ /^[\w-]+$/
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $params = CCNQ::Portal::Util::neat({
    account     => session('account'),
  }, qw(
    account_sub
    name
    plan
  ));

  return CCNQ::Portal::content unless params->{account_sub};
  return CCNQ::Portal::content unless params->{account_sub} =~ /^[\w-]+$/;

  return CCNQ::Portal::content unless params->{name};
  return CCNQ::Portal::content unless params->{plan};

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update('account_sub',$params,$cv1);
  return CCNQ::Portal::Util::redirect_request($cv1);
}

post '/billing/account_sub/:account_sub' => sub { handle_account_sub() };
post '/billing/account_sub'              => sub { handle_account_sub() };

# List all accounts
get  '/billing/accounts' => sub {
  var template_name => 'api/accounts';

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content;

  my $cv = AE::cv;
  CCNQ::API::billing('report','accounts',$cv);

  var all_accounts => sub {
    return CCNQ::AE::receive_docs($cv) || [];
  };

  return CCNQ::Portal::content;
};

# Create new account
get '/billing/account/new' => sub {
  var template_name => 'api/account_new';

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  return CCNQ::Portal::content;
};

'CCNQ::Portal::Inner::Account';
