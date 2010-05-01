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

sub default {
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');

  my $account = session('account');

  my $endpoints = CCNQ::Portal::Inner::Endpoint::endpoints_for($account);

  if( params->{category} and
      vars->{category_to_criteria} and
      vars->{category_to_criteria}->{params->{category}} )
  {
    my $selector = vars->{category_to_criteria}->{params->{category}};
    my @remove = grep { ! $selector->($endpoints->{$_}) } keys %$endpoints;
    delete @$endpoints {@remove}; # hash splice
  }
  # and category_to_criteria->{params->{category}}->($endpoint)


  var field => {
    endpoints => $endpoints,
  };

  return CCNQ::Portal::content;
}

sub get_default {
  var template_name => 'api/number';
  default();
}

sub submit_number {
  my ($api_name) = @_;

  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');

  my $account  = session('account');

  my $endpoint = params->{endpoint};
  return CCNQ::Portal::content unless $endpoint;

  my $endpoint_data = CCNQ::Portal::Inner::Endpoint::get_endpoint($account,$endpoint);

  my $params = {
    account       => $endpoint_data->{account},
    account_sub   => $endpoint_data->{account_sub},
    endpoint      => $endpoint_data->{endpoint},
    endpoint_ip   => $endpoint_data->{ip},
    username      => $endpoint_data->{username},
    username_domain => $endpoint_data->{domain},
    cluster       => $endpoint_data->{cluster},
  };

  CCNQ::Portal::Util::neat($params,qw(
    number
    inbound_username
  ));

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update($api_name,$params,$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
}

sub submit_default {
  my ($category_to_route) = @_;

  var template_name => 'api/number';

  exists(vars->{cluster_to_profiles}->{params->{cluster}}) and
  exists(vars->{cluster_to_profiles}->{params->{cluster}}->{params->{inbound_username}}) and
  exists(vars->{category_to_criteria}->{params->{category}})
  # and category_to_criteria->{params->{category}}->($endpoint)
  or return CCNQ::Portal::content;

  CCNQ::Portal::Inner::Number::submit_number($category_to_route->{params->{category}});
}

1;
