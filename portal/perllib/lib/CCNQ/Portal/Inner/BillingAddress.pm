package CCNQ::Portal::Inner::BillingAddress;
# Copyright (C) 2010  Stephane Alnet
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

use Dancer ':syntax';

use CCNQ::Portal;
use CCNQ::Portal::Util;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Inner::Util;

=head1 SUMMARY

  CCNQ::Portal::Inner::BillingAddress displays and validates a form
  to update the billing address of a given account.

=cut

get '/billing/account_address' => sub {
  var template_name => 'api/account_address';

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $account = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_);

  # Retrieve the account's data.
  my $cv = AE::cv;
  CCNQ::API::billing('report','accounts',$account,$cv);
  my $data = CCNQ::AE::receive_first_doc($cv) || {};
  var billing_address => $data->{billing_address};

  return CCNQ::Portal::content;

};

post '/billing/account_address' => sub {
  var template_name => 'api/account_address';

  my $account = CCNQ::Portal::Inner::Util::validate_account;

  CCNQ::Portal->current_session->user &&
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_);

  # Customers cannot update their own addresses.
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  # Retrieve the account's data.
  my $cv = AE::cv;
  CCNQ::API::billing('report','accounts',$account,$cv);
  my $data = CCNQ::AE::receive_first_doc($cv) || {};

  my $billing_address = CCNQ::Portal::Util::neat({},qw(
    addr1
    addr2
    addr3
    addr4
    city
    state
    zip
    billing_phone
  ));

  $data->{billing_address} = $billing_address;

  # Save the new account information.
  my $cv2 = AE::cv;
  CCNQ::API::api_update('account',$data,$cv2);
  return CCNQ::Portal::Util::redirect_request($cv2);
};

'CCNQ::Portal::Inner::BillingAddress';
