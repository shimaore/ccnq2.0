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

use CCNQ::AE;
use CCNQ::API;

sub gather_field {
  my $account = session('account');

  # Get the information from the portal.
  # e.g. print a list of users who have portal access to this account
  my $cv1 = CCNQ::Portal::db->view('report/portal_users_by_account', {
    startkey => [$account],
    endkey   => [$account,{}],
  });
  my $portal_users = CCNQ::AE::receive($cv1);
  my @portal_users = map { $_->{id} } @{$portal_users->{rows} || []};

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::billing_view('accounts',$account,$cv2);
  my $account_billing_data = CCNQ::AE::receive($cv2) || {};

  # e.g. print a list of users who receive bills for this account
  # .. that'd be the keys of the 'email_recipients' hash.

  # e.g. print a list of account_subs for this account
  my $cv3 = AE::cv;
  CCNQ::API::billing_view('account_subs',$account,$cv3);
  my $account_subs = CCNQ::AE::receive($cv3);
  my @account_subs = map { $_->{doc} } @{$account_subs->{rows} || []};

  # e.g. print account details.
  var field => {
    name    => $account_billing_data->{name},
    account => $account,
    portal_users => [@portal_users],
    account_subs => [@account_subs],
  };
}

sub gather_field_sub {
  my $account = session('account');
  my $account_sub = session('account_sub');

  # Get the information from the portal.

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::billing_view('account_subs',$account,$account_sub,$cv2);
  my $account_sub_billing_data = CCNQ::AE::receive($cv2) || {};

  var field => {
    name    => $account_sub_billing_data->{name},
    plan    => $account_sub_billing_data->{plan},
    account => $account,
    account_sub => $account_sub,
  };
}

get '/api/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');

  gather_field();

  var template_name => 'api/account';
  return CCNQ::Portal->site->default_content->();
};

use CCNQ::Billing;

post '/api/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');

  my $account = session('account');

  my $name = params->{name};
  $name =~ s/^\s+//; $name =~ s/^\s+$//; $name =~ s/\s+/ /g;

  # Update the information in the portal.
  # N/A -- no native account-related information is stored in the portal.
  # ("portal_accounts" is a property of the portal user.)

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update({
    action        => 'account',
    cluster_name  => CCNQ::Billing::BILLING_CLUSTER_NAME(),
    account       => $account,
    name          => $name,
  },$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

get '/api/account_sub/:account_sub' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  return unless params->{account_sub};

  session account_sub => params->{account_sub};

  gather_field_sub();

  var template_name => 'api/account_sub';
  return CCNQ::Portal->site->default_content->();
};

post '/api/account_sub' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  return unless params->{account_sub};

  session account_sub => params->{account_sub};

  my $name = params->{name};
  $name =~ s/^\s+//; $name =~ s/^\s+$//; $name =~ s/\s+/ /g;

  my $plan = params->{plan};

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update({
    action        => 'account',
    cluster_name  => CCNQ::Billing::BILLING_CLUSTER_NAME(),

    account     => session('account'),
    account_sub => session('account_sub'),
    name => $name,
    plan => $plan,
  },$cv1);
  my $r = CCNQ::AE::receive($cv1);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

'CCNQ::Portal::Inner::Account';
