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

get '/api/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');

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
  CCNQ::API::billing_view('account',$account,$cv2);
  my $account_billing_data = CCNQ::AE::receive($cv2) || {};

  # e.g. print a list of users who receive bills for this account
  # .. that'd be the keys of the 'email_recipients' hash.

  # e.g. print a list of account_subs for this account
  my $cv3 = AE::cv;
  CCNQ::API::billing_view('account_sub',$account,$cv3);
  my $account_subs = CCNQ::AE::receive($cv3);
  my @account_subs = map { $_->{doc} } @{$account_subs->{rows} || []};

  # e.g. print account details.
  var field => {
    name    => $account_billing_data->{name},
    account => $account,
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
