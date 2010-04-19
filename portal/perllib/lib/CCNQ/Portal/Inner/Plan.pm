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

use CCNQ::AE;
use CCNQ::API;

use JSON;

sub gather_plans {
  my $account = session('account');
  my $cv = AE::cv;
  CCNQ::API::billing_view('report','plans',$cv);
  my $r = CCNQ::AE::receive($cv) || { rows => [] };
  return map { $_->{doc} } @{$r->{rows}};
}

sub gather_currencies {
  return { 'EUR' => '€', 'USD' => 'US$' };
}

sub gather_field {
  my $plan = session('plan');

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::billing_view('report','plans',$plan,$cv2);
  my $r2 = CCNQ::AE::receive($cv2) || { rows => [] };
  my $plan_data = $r2->{rows}->[0]->{doc} || { decimals => 2 };

  # e.g. print account details.
  var field => {
    plan          => $plan,
    name          => $plan_data->{name},
    currency      => $plan_data->{currency},
    decimals      => $plan_data->{decimals},
    rating_steps  => encode_json($plan_data->{rating_steps}),

    plans         => [gather_plans()],
    currencies    => gather_currencies(),
  };
}

post '/billing/plan' => sub {
  return unless CCNQ::Portal->current_session->user;

  return unless params->{plan} =~ /^[\w-]+$/;

  my $plan = params->{plan};
  gather_field($plan);

  var template_name => 'api/plan';
  return CCNQ::Portal->site->default_content->();
};

get '/billing/plan' => sub {
  return unless CCNQ::Portal->current_session->user;

  var field => {
    plans         => [gather_plans()],
    currencies    => [gather_currencies()],
  };
  var template_name => 'api/plan';
  return CCNQ::Portal->site->default_content->();
};

get '/billing/plan/:plan' => sub {
  return unless CCNQ::Portal->current_session->user;

  return unless params->{plan} =~ /^[\w-]+$/;

  my $plan = params->{plan};
  gather_field($plan);

  var template_name => 'api/plan';
  return CCNQ::Portal->site->default_content->();
};

post '/billing/plan/:plan' => sub {
  return unless CCNQ::Portal->current_session->user;

  return unless params->{plan} =~ /^[\w-]+$/;

  my $plan = params->{plan};

  my $name = params->{name};
  $name =~ s/^\s+//; $name =~ s/^\s+$//; $name =~ s/\s+/ /g;

  my $currency = params->{currency};
  # XXX validate currency

  my $decimals = params->{decimals};

  my $rating_steps = decode_json(params->{rating_steps});

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update({
    action        => 'plan',
    cluster_name  => 'none',
    plan          => $plan,
    name          => $name,
    currency      => $currency,
    decimals      => $decimals,
    rating_steps  => $rating_steps,

    currencies    => gather_currencies(),
  },$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

'CCNQ::Portal::Inner::Plan';
