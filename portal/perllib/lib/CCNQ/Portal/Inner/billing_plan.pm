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
use CCNQ::Billing::Table;
use CCNQ::Portal::Inner::Util;

get '/billing/billing_plan/:plan_name' => sub {
  my $params = CCNQ::Portal::Util::neat({},qw(plan_name));
  my $plan_name = $params->{plan_name};

  $plan_name =~ /\S/ or
    return CCNQ::Portal::content( error => _('no plan_name')_ );

  var template_name => 'api/billing_plan';
  return unless CCNQ::Portal->current_session->user;
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  var all_tables  => sub { CCNQ::AE::receive(CCNQ::Billing::Table::all_tables) };
  var get_buckets => \&CCNQ::Portal::Inner::Util::get_buckets;
  var get_currencies  => \&CCNQ::Portal::Inner::Util::get_currencies;

  var plan_name => $plan_name;

  return CCNQ::Portal::content;
};

get '/json/billing/billing_plan' => sub {
  my $params = CCNQ::Portal::Util::neat({},qw(plan_name));
  my $plan_name = $params->{plan_name};

  content_type 'text/json';

  $plan_name =~ /\S/ or
    return to_json({ error => 'no plan_name' });

  my $cv = AE::cv;
  CCNQ::API::billing('report','plans',$plan_name,$cv);
  my $plan_data = CCNQ::AE::receive_first_doc($cv) || { name => $plan_name, decimals => 2 };

  return to_json($plan_data);
};

post '/json/billing/billing_plan' => sub {
  my $params = CCNQ::Portal::Util::neat({},qw(plan_name rating_steps));
  my $plan_name    = $params->{plan_name};
  my $rating_steps = $params->{rating_steps};

  content_type 'text/json';

  $plan_name =~ /\S/ or
    return to_json({ error => 'no plan_name' });

  $rating_steps or
    return to_json({ error => 'no rating_steps' });

  # XXX save data. we need to get the original plan, and replace its "rating_steps" with the parameters we got.
  return to_json({ ok => 'true' });
};

'CCNQ::Portal::Inner::billing_plan';
