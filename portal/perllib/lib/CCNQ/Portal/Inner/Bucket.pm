package CCNQ::Portal::Inner::Bucket;
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
use utf8;

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;
use CCNQ::Portal::Inner::Util;

use CCNQ::AE;
use CCNQ::API;

get  '/bucket/' => sub {
  var template_name => 'api/bucket/select';

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var get_buckets        => \&CCNQ::Portal::Inner::Util::get_buckets;
  var get_currencies     => \&CCNQ::Portal::Inner::Util::get_currencies;

  return CCNQ::Portal::content;
};

post '/bucket/' => sub {
  var template_name => 'api/bucket/select';

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $params = CCNQ::Portal::Util::neat({},qw(
    name use_account currency increment decimals cap
  ));

  $params->{name} =~ /\S/ or die "name is required";

  my $cv = AE::cv;
  CCNQ::API::api_update('bucket',$params,$cv);
  return CCNQ::Portal::Util::redirect_request($cv);
};

'CCNQ::Portal::Inner::Bucket';
