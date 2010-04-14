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

get '/api/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  
  # Get the information from the portal.
  # e.g. print a list of users who have portal access to this account
  my $cv1 = CCNQ::Portal::db->view('report/portal_users_by_account', {
    startkey => [session('account')],
    endkey   => [session('account'),{}],
  });
  my $portal_users = $cv1->recv;
  my @portal_users = map { $_->{id} } @{$portal_users->{rows}};

  # Get the information from the API.
  my $cv2 = AE::cv;
  my $params2 = {
    action         => 'retrieve_account',
    cluster_name   => 'billing',
    account        => session('account'),
  };
  CCNQ::API::api_query($params2,$cv2);
  my $account_billing_data = $cv2->recv;

  # e.g. print a list of users who receive bills for this account
  # .. that'd be the keys of the 'email_recipients' hash.

  # e.g. print a list of account_subs for this account
  my $cv3 = AE::cv;
  my $params3 = {
    action         => 'billing_view',
    cluster_name   => 'billing',
    view           => 'account_subs',
    _id            => [session('account')],
  };
  CCNQ::API::api_query($params3,$cv3);
  my $account_subs = $cv3->recv;
  my @account_subs = map { $_->{doc} } @{$account_subs->{rows}};

  # e.g. print account details.
  var field => {
    %$account_billing_data,
    portal_users => [@portal_users],
    account_subs => [@account_subs],
  };
  
  var template_name => 'api/account';
  return CCNQ::Portal->site->default_content->();
};

post '/api/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');

  # Update the information in the portal.
  
  # Update the information in the API.  
  
  var template_name => 'api/account';
  return CCNQ::Portal->site->default_content->();
};

# XXX post ...

'CCNQ::Portal::Inner::Account';
