package CCNQ::Portal::Inner::Bucket::Instance;
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
use utf8;

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;
use CCNQ::Portal::Inner::Util;

use CCNQ::AE;
use CCNQ::API;

#

get  '/bucket/account/' => sub {
  var template_name => 'api/bucket/account';

  CCNQ::Portal->current_session->user &&
  session('account')
    or return CCNQ::Portal::content;

  var get_buckets        => \&CCNQ::Portal::Inner::Util::get_buckets;
  var get_account_bucket => \&CCNQ::Portal::Inner::Util::get_account_bucket;
  var account_subs       => \&CCNQ::Portal::Inner::Util::account_subs;

  return CCNQ::Portal::content;
};

post '/bucket/account/' => sub {
  var template_name => 'api/bucket/select';

  CCNQ::Portal->current_session->user                    &&
  CCNQ::Portal->current_session->user->profile->is_admin &&
  session('account')
    or return CCNQ::Portal::content;

  my $params = CCNQ::Portal::Util::neat({
    account => session('account'),
  },qw(
    name
    account_sub
    value
    currency
  ));

  my $cv = AE::cv;
  CCNQ::API::bucket_update($params,$cv);
  my $r = CCNQ::AE::receive($cv);

  var error => $r->{error};
  var response => $r;
  return CCNQ::Portal::content;
};

'CCNQ::Portal::Inner::Bucket::Instance';
