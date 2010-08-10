package CCNQ::Portal::Inner::Number::Bank;
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
use CCNQ::Portal::Util;
use CCNQ::Portal::Inner::Util;

use CCNQ::Activities::Number;
use CCNQ::Portal::Inner::Number;

use CCNQ::AE;
use CCNQ::API;

=head1 CCNQ::Portal::Inner::Number::Bank

The "numbers bank" is used to store DIDs which are not associated with
a particular endpoint.

When a customer's DID is no longer needed, it is returned to the bank;
its configuration (routing) is removed, and it is disassociated from
its endpoint and account.

It can be put back in production e.g. by a customer requesting a new number
to be assigned.

=cut

=head2 /numbers/bank/available

Returns all available numbers.

=head2 /number/bank/available?number_type=type

Returns all available numbers of the given type.

(A number_type is a site-dependent value, used to allow customer self-
provisioning.)

=cut

sub to_html {
  my $cv = shift;
  var template_name => 'api/number-bank';
  var number_types => CCNQ::Portal::Inner::Number->registered_number_types;
  $cv and var result => sub { CCNQ::AE::receive($cv) };
  return CCNQ::Portal::content;
}

sub as_json {
  my $cv = shift;
  $cv or return send_error();
  content_type 'text/json';
  return to_json( CCNQ::AE::receive($cv));
}

sub _get_bank_numbers {
  CCNQ::Portal->current_session->user
    or return;

  # optional
  my $number_type = params->{number_type};

  my $cv = AE::cv;

  if($number_type) {
    CCNQ::API::provisioning('report','number_bank_by_type',$number_type,$cv);
  } else {
    # Restrict the generic view to administrators
    CCNQ::Portal->current_session->user->profile->is_admin
      or return;
    CCNQ::API::provisioning('report','number_bank',$cv);
  }
  return $cv;
}

get       '/numbers/bank/' => sub { to_html _get_bank_numbers };
get  '/json/numbers/bank/' => sub { as_json _get_bank_numbers };

=head2 PUT /numbers/bank?number=...

  Inserts a new number in the numbers bank.

=cut

post '/numbers/bank/create' => sub {
  CCNQ::Portal->current_session->user
  && CCNQ::Portal->current_session->user->profile->is_admin
    or return;

  my $number = CCNQ::Portal::normalize_number(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','all_numbers',$number,$cv);
  my $number_data = CCNQ::AE::receive_first_doc($cv);
  $number_data
    and return CCNQ::Portal::content( error => _('This number already exists. Please delete it first.')_ );

  my $params = CCNQ::Portal::Util::neat({}, grep { !/^_/ } keys %{ params });

  # Extra fields might be available: number_type, country, ratecenter, etc.
  $params = {
    %$params,
    number => $number,
    profile => 'number',
  };

  CCNQ::Activities::Number->is_bare_record($params)
    or return CCNQ::Portal::content( error => _('Invalid parameters.')_ );

  my $cv2 = AE::cv;
  CCNQ::API::api_update('number_bank',$params,$cv2);
  return CCNQ::Portal::Util::redirect_request($cv2);
};

=head2 POST /numbers/bank?number=...

  Modify a number in the numbers bank.

=cut

post '/numbers/bank/modify' => sub {
  CCNQ::Portal->current_session->user
  && CCNQ::Portal->current_session->user->profile->is_admin
    or return;

  my $number = CCNQ::Portal::normalize_number(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','number_bank',$number,$cv);
  my $number_data = CCNQ::AE::receive_first_doc($cv);
  $number_data
    or return CCNQ::Portal::content( error => _('Please create this number first.')_ );

  my $params = CCNQ::Portal::Util::neat($number_data, grep { !/^_/ } keys params);

  $params = {
    %$params,
    number => $number,
    profile => 'number',
  };

  CCNQ::Activities::Number->is_bare_record($params)
    or return CCNQ::Portal::content( error => _('Invalid parameters.')_ );

  my $cv2 = AE::cv;
  CCNQ::API::api_update('number_bank',$params,$cv2);
  return CCNQ::Portal::Util::redirect_request($cv2);
};

=head2 DELETE /numbers/bank?number=...

  Delete a number from the numbers bank.

=cut

post '/numbers/bank/delete' => sub {
  CCNQ::Portal->current_session->user
  && CCNQ::Portal->current_session->user->profile->is_admin
    or return;

  my $number = CCNQ::Portal::normalize_number(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','number_bank',$number,$cv);
  my $params = CCNQ::AE::receive_first_doc($cv);
  $params
    or return CCNQ::Portal::content( error => _('Number does not exist.')_ );

  my $cv2 = AE::cv;
  CCNQ::API::api_delete('number_bank',$params,$cv2);
  return CCNQ::Portal::Util::redirect_request($cv2);
};

=head2 POST /numbers/bank/return/:number

  Return a number to the bank.

  CCNQ::Activities::Number makes sure the number is actually a bank number.

=cut

post '/numbers/bank/return/:number' => sub {
  CCNQ::Portal->current_session->user
    or return;

  my $number = CCNQ::Portal::normalize_number(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $account = session('account');

  my $number_data = get_number($account,$number);
  $number_data
    or return CCNQ::Portal::content( error => _('No such number')_ );

  my $api_name = $number_data->{api_name};
  $api_name
    or return CCNQ::Portal::content( error => _('Cannot return number to the bank')_ );

  # Submit in the API.
  my $cv = AE::cv;
  CCNQ::API::api_delete($api_name,$number_data,$cv);
  return CCNQ::Portal::Util::redirect_request($cv);
};

1;
