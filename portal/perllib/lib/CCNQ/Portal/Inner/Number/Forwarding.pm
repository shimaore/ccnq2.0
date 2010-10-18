package CCNQ::Portal::Inner::Number::Forwarding;
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
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;
use CCNQ::Portal::Inner::Util;

use CCNQ::AE;
use CCNQ::API;

# Customer-facing forwarding tools
# Allows for "Never", "Always" and "On Failure".

get  '/number_forwarding/:number' => sub {
  my $normalize_number = \&CCNQ::Portal::normalize_number;

  var template_name => 'api/number-forwarding';

  my $account = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $number = $normalize_number->(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $number_data = CCNQ::Portal::Inner::Util::get_number($account,$number);

  # Old data
  my $type = $number_data->{forwarding_type};
  if($type) {
    if($type eq 'all') {
      $number_data->{cfa_number} = $number_data->{forwarding_number};
      $number_data->{cfa_mode}   = $number_data->{forwarding_mode};
    }
    if($type eq 'err') {
      $number_data->{cfda_number} = $number_data->{forwarding_number};
      $number_data->{cfda_mode}   = $number_data->{forwarding_mode};
      $number_data->{cfb_number}  = $number_data->{forwarding_number};
      $number_data->{cfb_mode}    = $number_data->{forwarding_mode};
      if($number_data->{register}) {
        $number_data->{cfnr_number} = $number_data->{forwarding_number};
        $number_data->{cfnr_mode}   = $number_data->{forwarding_mode};
      }
    }
  }
  # /Old data

  # Default value specified in
  $number_data->{cfda_timeout} ||= 90;

  var field => $number_data;
  return CCNQ::Portal::content;
};

post '/number_forwarding/:number' => sub {
  my $normalize_number = \&CCNQ::Portal::normalize_number;

  var template_name => 'api/number-forwarding';

  my $account  = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $number = $normalize_number->(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $params = {};
  CCNQ::Portal::Util::strip($params,qw(
    cfa_number    cfa_mode
    cfnr_number   cfnr_mode
    cfda_number   cfda_mode   cfda_timeout
    cfb_number    cfb_mode
  ));

  for my $i (qw(cfa cfnr cfda cfb)) {
    my $n = $i.'_number';
    $params->{$n} = $normalize_number->($params->{$n});
  }

  return CCNQ::Portal::Inner::Util::update_number($account,$number,$params);
};

'CCNQ::Portal::Inner::Number::Forwarding';
