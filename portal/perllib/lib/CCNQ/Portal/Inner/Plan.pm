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
use utf8;

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;

use CCNQ::AE;
use CCNQ::API;

use JSON;

sub gather_plans {
  my $account = session('account');
  my $cv = AE::cv;
  CCNQ::API::billing_view('report','plans','',$cv);
  my $r = CCNQ::AE::receive($cv) || { rows => [] };
  my @plans = map { $_->{doc} } @{$r->{rows}};
  return [@plans];
}

sub gather_currencies {
  return { 'EUR' => '€', 'USD' => 'US$' };
}

sub gather_field {
  my ($plan_name) = @_;

  debug("Gathering data for plan $plan_name");

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::billing_view('report','plans',$plan_name,$cv2);
  my $r2 = CCNQ::AE::receive($cv2) || { rows => [] };
  my $plan_data = $r2->{rows}->[0]->{doc} || { name => $plan_name, decimals => 2 };

  my $field = {
    name          => $plan_data->{name},
    currency      => $plan_data->{currency},
    decimals      => $plan_data->{decimals},

    plans         => \&gather_plans,
    currencies    => \&gather_currencies,
  };

  if($plan_data->{rating_steps}) {
    $field->{rating_steps} = eval { encode_json($plan_data->{rating_steps}) };
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

  var field => {
    plans         => \&gather_plans,
    currencies    => \&gather_currencies,
  };
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
    my $rating_steps = eval { decode_json($params->{rating_steps}) };
    if($@) {
      var error => _('Invalid JSON content')_;
      my $fields = $params;
      $fields->{currencies} = \&gather_currencies;
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
