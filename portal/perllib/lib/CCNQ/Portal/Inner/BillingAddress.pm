package CCNQ::Portal::Inner::BillingAddress;
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

use Dancer ':syntax';

use CCNQ::Portal;
use CCNQ::Portal::I18N;

use Geo::PostalAddress;

=head1 SUMMARY

  CCNQ::Portal::Inner::BillingAddress displays and validates a form
  to update the billing address of a given account.

=cut

get '/billing/account_address' => sub {
  var template_name => 'api/account_address';

  return unless CCNQ::Portal->current_session->user;
  return unless session('account');

  # Retrieve the account's data.
  my $cv = AE::cv;
  CCNQ::API::billing('report','accounts',session('account'),$cv);
  my $data = CCNQ::AE::receive_first_doc($cv) || {};
  var account_billing_data => $data;

  # Gather the names of fields for the specific country.
  my $address_parser = Geo::PostalAddress->new(uc($data->{country}));
  $address_parser or return CCNQ::Portal::content( error => _('Please correct the billing country code')_ );
  var account_address_format => $address_parser->format();

  # Retrieve the account's specific address data.
  var address => $address_parser->display($data->{address});
  return CCNQ::Portal::content;

};

post '/billing/account_address' => sub {
  var template_name => 'api/account_address';

  return unless CCNQ::Portal->current_session->user;
  return unless session('account');

  # Customers cannot update their own addresses.
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  # Retrieve the account's data.
  my $cv = AE::cv;
  CCNQ::API::billing('report','accounts',session('account'),$cv);
  my $data = CCNQ::AE::receive_first_doc($cv) || {};

  # Update the address if the one that was submitted is valid.
  my $address_parser = Geo::PostalAddress->new(uc($data->{country}));
  my $new_address = $address_parser->storage(params);
  ref($new_address) or return CCNQ::Portal::content( error => _($new_address)_ );

  $data->{address} = $new_address;

  # Save the new account information.
  my $cv2 = AE::cv;
  CCNQ::API::api_update('account',$data,$cv2);
  return CCNQ::Portal::Util::redirect_request($cv2);
};

'CCNQ::Portal::Inner::BillingAddress';
