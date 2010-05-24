package CCNQ::Portal::Inner::Plan;
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
use CCNQ::Portal::Util;

use CCNQ::AE;
use CCNQ::API;

sub gather_field {
  my ($plan_name) = @_;

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::billing('report','plans',$plan_name,$cv2);
  my $plan_data = CCNQ::AE::receive_first_doc($cv2) || { name => $plan_name, decimals => 2 };

  var get_plans       => \&CCNQ::Portal::Inner::Util::get_plans;
  var get_currencies  => \&CCNQ::Portal::Inner::Util::get_currencies;

  my $field = {
    name          => $plan_data->{name},
    currency      => $plan_data->{currency},
    decimals      => $plan_data->{decimals},

  };

  if($plan_data->{rating_steps}) {
    $field->{rating_steps} = eval { to_json($plan_data->{rating_steps}) };
  }

  var field => $field;
}

post '/billing/plan' => sub {
  var template_name => 'api/plan';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_sysadmin;

  my $params = CCNQ::Portal::Util::neat({},qw(name));
  return unless $params->{name} =~ /\S/;

  gather_field($params->{name});

  return CCNQ::Portal::content;
};

get '/billing/plan' => sub {
  var template_name => 'api/plan';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;

  var get_plans       => \&CCNQ::Portal::Inner::Util::get_plans;
  var get_currencies  => \&CCNQ::Portal::Inner::Util::get_currencies;

  return CCNQ::Portal::content;
};

get '/billing/plan/:name' => sub {
  var template_name => 'api/plan';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;

  my $params = CCNQ::Portal::Util::neat({},qw(name));
  return unless $params->{name} =~ /\S/;

  gather_field($params->{name});

  return CCNQ::Portal::content;
};

post '/billing/plan/:name' => sub {
  var template_name => 'api/plan';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_sysadmin;

  my $params = CCNQ::Portal::Util::neat({},qw(
    name
    currency
    decimals
    rating_steps
  ));

  return unless $params->{name} =~ /\S/;

  # XXX validate currency

  if(params->{rating_steps}) {
    my $rating_steps = eval { from_json($params->{rating_steps}) };
    if($@) {
      debug("JSON Error: $@");
      var error => _('Invalid JSON content ([_1]): [_2]',$@,$params->{rating_steps})_;
      my $fields = $params;
      var get_currencies  => \&CCNQ::Portal::Inner::Util::get_currencies;
      var field => $fields;
      var template_name => 'api/plan';
      return CCNQ::Portal::content;
    }
    $params->{rating_steps} = $rating_steps;
  }

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update('plan',$params,$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

'CCNQ::Portal::Inner::Plan';
