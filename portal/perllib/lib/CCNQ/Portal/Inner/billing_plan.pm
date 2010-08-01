package CCNQ::Portal::Inner::billing_plan;
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
use CCNQ::Rating::Table;

get '/billing/billing_plan' => sub {
  var template_name => 'api/billing_plan';
  return unless CCNQ::Portal->current_session->user;
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  var all_tables  => sub { CCNQ::AE::Receive(CCNQ::Billing::Table::all_tables) };
  var get_buckets => \&CCNQ::Portal::Inner::Util::get_buckets;

  return CCNQ::Portal::content;
};

# XXX post ...

'CCNQ::Portal::Inner::billing_plan';
