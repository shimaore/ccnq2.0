package CCNQ::Portal::Inner::Number::Location;
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

sub get {
  my ($normalize_number) = @_;

  var template_name => 'api/number-location';

  my $account = session('account');

  my $number = $normalize_number->(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $number_data = CCNQ::Portal::Inner::Util::get_number($account,$number);
  var field => $number_data;
  return CCNQ::Portal::content;
}

sub submit {
  my ($normalize_number) = @_;

  my $account  = session('account');

  my $number = $normalize_number->(params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $params = {};
  CCNQ::Portal::Util::neat($params,qw(
    location
  ));

  return CCNQ::Portal::Inner::Util::update_number($account,$number,$params);
}

'CCNQ::Portal::Inner::Number::Location'