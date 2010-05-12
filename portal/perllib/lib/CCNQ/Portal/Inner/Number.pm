package CCNQ::Portal::Inner::Number;
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

use CCNQ::AE;
use CCNQ::API;

use CCNQ::Portal;
use CCNQ::Portal::Inner::Endpoint;

# Generic get/update

sub get_number {
  my ($account,$number) = @_;
  my $cv = AE::cv;
  CCNQ::API::provisioning_view('report','number',$account,$number,$cv);
  my $numbers = CCNQ::AE::receive($cv);
  return $numbers->{rows}->[0]->{doc} || {};
}

sub _update_number {
  my ($account,$number,$new_data) = @_;

  my $number_data = get_number($account,$number);

  my $params = {
    %$number_data, # Keep any existing information (this means data must be overwritten)
    %$new_data,
  };

  my $api_name = $params->{api_name};
  return CCNQ::Portal::content unless $api_name;

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update($api_name,$params,$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
}

# Number routing form.
# This updates:
#  - the endpoint
#  - the "profile" on the client-sbc

sub default {
  my ($category_to_criteria) = @_;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');

  my $account = session('account');

  my $endpoints = CCNQ::Portal::Inner::Endpoint::endpoints_for($account);

  my $category = params->{category};
  my $cluster  = params->{cluster};

  if( $category and
      $category_to_criteria and
      $category_to_criteria->{$category} )
  {
    my $selector = $category_to_criteria->{$category};
    $endpoints = [ grep { $selector->($_) } @$endpoints ];
  }

  var field => {
    endpoints => $endpoints,
  };
  var category => $category;
  var cluster  => $cluster;

  return CCNQ::Portal::content;
}

sub get_default {
  var template_name => 'api/number';
  default(@_);
}

sub submit_number {
  my ($api_name,$normalize_number) = @_;

  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');

  my $account  = session('account');

  my $endpoint = params->{endpoint};
  return CCNQ::Portal::content unless $endpoint;

  my $endpoint_data = CCNQ::Portal::Inner::Endpoint::get_endpoint($account,$endpoint);

  my $params = {
    api_name      => $api_name,
    account       => $endpoint_data->{account},
    account_sub   => $endpoint_data->{account_sub},
    endpoint      => $endpoint_data->{endpoint},
    endpoint_ip   => $endpoint_data->{ip},
    register      => $endpoint_data->{password} ? 1 : 0,
    username      => $endpoint_data->{username},
    username_domain => $endpoint_data->{domain},
    cluster       => $endpoint_data->{cluster},
  };

  CCNQ::Portal::Util::neat($params,qw(
    number
    inbound_username
  ));

  my $number = $params->{number};
  $number = $normalize_number->($number) if defined $normalize_number;
  unless($number) {
    var error => _('Please specify a valid number')_;
    return CCNQ::Portal::content;
  }

  return _update_number($account,$number,$params);
}

sub submit_default {
  my ($category_to_route,$normalize_number) = @_;

  var template_name => 'api/number';

  exists(vars->{cluster_to_profiles}->{params->{cluster}}) and
  exists(vars->{cluster_to_profiles}->{params->{cluster}}->{params->{inbound_username}}) and
  exists(vars->{category_to_criteria}->{params->{category}})
  # and category_to_criteria->{params->{category}}->($endpoint)
  or return CCNQ::Portal::content;

  return CCNQ::Portal::Inner::Number::submit_number($category_to_route->{params->{category}},$normalize_number);
}

# Customer-facing forwarding tools
# Allows for "Never", "Always" and "On Failure".

sub get_forwarding {
  my ($normalize_number) = @_;

  var template_name => 'api/number-forwarding';

  my $account = session('account');

  my $number = params->{number};
  $number = $normalize_number->($number) if defined $normalize_number;
  unless($number) {
    var error => _('Please specify a valid number')_;
    return CCNQ::Portal::content;
  }

  my $number_data = get_number($account,$number);
  var field => $number_data;
  return CCNQ::Portal::content;
}

sub submit_forwarding {
  my ($category_to_route,$normalize_number) = @_;

  var template_name => 'api/number-forwarding';

  my $account  = session('account');

  my $number = params->{number};
  $number = $normalize_number->($number) if defined $normalize_number;
  unless($number) {
    var error => _('Please specify a valid number')_;
    return CCNQ::Portal::content;
  }

  my $params = {};
  CCNQ::Portal::Util::neat($params,qw(
    forwarding_type
    forwarding_number
  ));

  my $forwarding_type = $params->{forwarding_type};
  return CCNQ::Portal::content unless grep { $forwarding_type eq $_ } qw( none all err );

  my $forwarding_number = $params->{forwarding_number};
  $forwarding_number = $normalize_number->($forwarding_number) if defined $normalize_number;

  # Forwarding number must be provided for all types except "none"/Never.
  if( $forwarding_type ne 'none' && !$forwarding_number ) {
    var error => _('Please specify a valid forwarding number')_;
    return CCNQ::Portal::content;
  }

  $params->{forwarding_number} = $forwarding_number;

  return _update_number($account,$number,$params);
}

1;
