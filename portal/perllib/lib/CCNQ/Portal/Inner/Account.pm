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

sub gather_plans {
  my $account = session('account');
  my $cv = AE::cv;
  CCNQ::API::billing_view('report','plans',$cv);
  my $r = CCNQ::AE::receive($cv) || { rows => [] };
  return map { $_->{doc} } @{$r->{rows}};
}

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
  CCNQ::API::billing_view('report','accounts',$account,$cv2);
  my $r2 = CCNQ::AE::receive($cv2) || { rows => [] };
  my $account_billing_data = $r2->{rows}->[0]->{doc} || {};

  # e.g. print a list of users who receive bills for this account
  # .. that'd be the keys of the 'email_recipients' hash.

  # e.g. print a list of account_subs for this account
  my $cv3 = AE::cv;
  CCNQ::API::billing_view('report','account_subs',$account,$cv3);
  my $account_subs = CCNQ::AE::receive($cv3);
  my @account_subs = map { $_->{doc} } @{$account_subs->{rows} || []};

  # e.g. print account details.
  var field => {
    name    => $account_billing_data->{name},
    account => $account,
    portal_users => [@portal_users],
    account_subs => [@account_subs],
    plans        => [gather_plans()],
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
    plans   => [gather_plans()],
  };
}

get '/billing/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  return unless session('account') =~ /^[\w-]+$/;

  gather_field();

  var template_name => 'api/account';
  return CCNQ::Portal->site->default_content->();
};

post '/billing/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  return unless session('account') =~ /^[\w-]+$/;

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
    cluster_name  => 'none',
    account       => $account,
    name          => $name,
  },$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

get '/billing/account_sub/:account_sub' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  return unless session('account') =~ /^[\w-]+$/;
  return unless params->{account_sub};
  return unless params->{account_sub} =~ /^[\w-]+$/;

  my $account_sub = params->{account_sub};

  gather_field_sub($account_sub);

  var template_name => 'api/account_sub';
  return CCNQ::Portal->site->default_content->();
};

sub handle_account_sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  return unless session('account') =~ /^[\w-]+$/;
  return unless params->{account_sub};
  return unless params->{account_sub} =~ /^[\w-]+$/;

  my $account_sub = params->{account_sub};

  my $name = params->{name};
  $name =~ s/^\s+//; $name =~ s/^\s+$//; $name =~ s/\s+/ /g;

  my $plan = params->{plan};

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update({
    action        => 'account_sub',
    cluster_name  => 'none',

    account     => session('account'),
    account_sub => $account_sub,
    name => $name,
    plan => $plan,
  },$cv1);
  my $r = CCNQ::AE::receive($cv1);

  # Redirect to the request
  redirect '/request/'.$r->{request};
}

post '/billing/account_sub/:account_sub' => sub { handle_account_sub() };
put  '/billing/account_sub'              => sub { handle_account_sub() };

'CCNQ::Portal::Inner::Account';
