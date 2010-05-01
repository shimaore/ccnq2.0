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

use CCNQ::Portal::Inner::Plan;

sub account_subs {
  my $account = shift;
  my $cv3 = AE::cv;
  CCNQ::API::billing_view('report','account_subs',$account,$cv3);
  my $account_subs = CCNQ::AE::receive($cv3);
  my @account_subs = map { $_->{doc} } @{$account_subs->{rows} || []};
  return [@account_subs];
}

sub portal_users {
  my $account = shift;
  my $cv1 = CCNQ::Portal::db->view('report/portal_users_by_account', {
    startkey => [$account],
    endkey   => [$account,{}],
  });
  my $portal_users = CCNQ::AE::receive($cv1);
  my @portal_users = map { $_->{id} } @{$portal_users->{rows} || []};
  return [@portal_users];
}

sub gather_field {
  my $account = session('account');

  # Get the information from the portal.
  # e.g. print a list of users who have portal access to this account
  my $portal_users = portal_users($account);

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::billing_view('report','accounts',$account,$cv2);
  my $r2 = CCNQ::AE::receive($cv2) || { rows => [] };
  my $account_billing_data = $r2->{rows}->[0]->{doc} || {};

  # e.g. print a list of users who receive bills for this account
  # .. that'd be the keys of the 'email_recipients' hash.

  # e.g. print a list of account_subs for this account
  my $account_subs = account_subs($account);

  # e.g. print account details.
  var field => {
    name    => $account_billing_data->{name},
    account => $account,
    portal_users => $portal_users,
    account_subs => $account_subs,
    plans        => \&CCNQ::Portal::Inner::Plan::gather_plans,
  };
}

sub gather_field_sub {
  my $account = session('account');
  my $account_sub = shift;

  # Get the information from the portal.

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::billing_view('report','account_subs',$account,$account_sub,$cv2);
  my $r2 = CCNQ::AE::receive($cv2) || { rows => [] };
  my $account_sub_billing_data = $r2->{rows}->[0]->{doc} || {};

  var field => {
    name    => $account_sub_billing_data->{name},
    plan    => $account_sub_billing_data->{plan},
    account => $account,
    account_sub => $account_sub,
    plans   => \&CCNQ::Portal::Inner::Plan::gather_plans,
  };
}

get '/billing/account' => sub {
  var template_name => 'api/account';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  if( session('account') && session('account') =~ /^[\w-]+$/ ) {
    gather_field();
  }
  return CCNQ::Portal::content;
};

post '/billing/account' => sub {
  var template_name => 'api/account';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_admin;
  # This is how we create new accounts.
  if(params->{account} && params->{account} =~ /^[\w-]+$/) {
       session account => params->{account};
  }
  return CCNQ::Portal::content unless session('account');
  return CCNQ::Portal::content unless session('account') =~ /^[\w-]+$/;

  my $params = CCNQ::Portal::Util::neat({
    account => session('account')
  },qw(
    name
  ));

  # Update the information in the portal.
  # N/A -- no native account-related information is stored in the portal.
  # ("portal_accounts" is a property of the portal user.)

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update('account',$params,$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

get '/billing/account_sub/:account_sub' => sub {
  var template_name => 'api/account_sub';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');
  return CCNQ::Portal::content unless session('account') =~ /^[\w-]+$/;
  return CCNQ::Portal::content unless params->{account_sub};
  return CCNQ::Portal::content unless params->{account_sub} =~ /^[\w-]+$/;

  my $account_sub = params->{account_sub};

  gather_field_sub($account_sub);

  return CCNQ::Portal::content;
};

get '/billing/account_sub' => sub {
  var template_name => 'api/account_sub';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');
  return CCNQ::Portal::content unless session('account') =~ /^[\w-]+$/;

  if( params->{account_sub} && params->{account_sub} =~ /^[\w-]+$/ ) {
    gather_field_sub(params->{account_sub});
  } else {
    var field => {
      plans   => \&CCNQ::Portal::Inner::Plan::gather_plans,
    }
  }

  return CCNQ::Portal::content;
};

sub handle_account_sub {
  var template_name => 'api/account_sub';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_admin;
  return CCNQ::Portal::content unless session('account');
  return CCNQ::Portal::content unless session('account') =~ /^[\w-]+$/;

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
  my $r = CCNQ::AE::receive($cv1);

  # Redirect to the request
  redirect '/request/'.$r->{request};
}

post '/billing/account_sub/:account_sub' => sub { handle_account_sub() };
post '/billing/account_sub'              => sub { handle_account_sub() };

'CCNQ::Portal::Inner::Account';
