package CCNQ::Portal::Inner::Number::Name;
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

use CCNQ::AE;
use CCNQ::API;

get  '/number_name/:number' => sub {
  var template_name => 'api/number-name';

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $account = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $number = CCNQ::Portal::normalize_number(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $number_data = CCNQ::Portal::Inner::Util::get_number($account,$number);
  $number_data
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var field => $number_data;
  return CCNQ::Portal::content;
};

post '/number_name/:number' => sub {
  var template_name => 'api/number-name';

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $account  = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $number = CCNQ::Portal::normalize_number(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $params = {};
  CCNQ::Portal::Util::neat($params,qw(
    name
  ));
  $params->{timestamp_name} = time();

  return CCNQ::Portal::Inner::Util::update_number($account,$number,$params);
};

1;
