package CCNQ::Portal::Inner::Endpoint;
# Copyright (C) 2009  Stephane Alnet
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

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;
use CCNQ::Portal::Inner::Util;
use CCNQ::Portal::Inner::Location;

use CCNQ::AE;
use CCNQ::API;

sub clean_params {
  my $params = {
    account       => CCNQ::Portal::Inner::Util::validate_account,
  };

  CCNQ::Portal::Util::neat($params,qw(
    cluster

    account_sub
    username
    domain

    password
    ip
    port
    srv
    via

    dest_domain

    location

  ));
  CCNQ::Portal::Util::strip($params,qw(
    strip_digit
    allow_onnet
    src_disabled
    dst_disabled
    always_proxy_media
    forwarding_sbc
    outbound_route
    ignore_caller_outbound_route
    ignore_default_outbound_route
    check_from
  ));
}

sub gather_field {
  my $params = clean_params();

  my $account = CCNQ::Portal::Inner::Util::validate_account;

  my $static_clusters  = CCNQ::Portal::Inner::Util::clusters_for_static_endpoints;
  var static_clusters  => $static_clusters;
  my $dynamic_clusters = CCNQ::Portal::Inner::Util::clusters_for_dynamic_endpoints;
  var dynamic_clusters => $dynamic_clusters;

  var endpoints_for => \&CCNQ::Portal::Inner::Util::endpoints_for;
  var account_subs  => \&CCNQ::Portal::Inner::Util::account_subs;
  var locations_for => \&CCNQ::Portal::Inner::Util::locations_for;

  # Gather data for a specific endpoint if needed
  my $endpoint = params->{endpoint};

  my $endpoint_data;
  if($endpoint) {
    $endpoint_data = CCNQ::Portal::Inner::Util::get_endpoint($account,$endpoint);
  } else {
    $params->{domain} ||= CCNQ::Install::cluster_fqdn($params->{cluster}) if $params->{cluster};
    $params->{password} ||= CCNQ::Portal::Util::random_password(16);
    $endpoint_data = $params;
  }

  my $is_static  = defined($endpoint_data->{cluster}) &&
    grep { $_ eq $endpoint_data->{cluster} } @$static_clusters;
  my $is_dynamic = defined($endpoint_data->{cluster}) &&
    grep { $_ eq $endpoint_data->{cluster} } @$dynamic_clusters;

  var field => {
    %$endpoint_data,
    is_static        => $is_static,
    is_dynamic       => $is_dynamic,
  };
}

sub endpoint_default {
  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );
  CCNQ::Portal::Inner::Util::validate_account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );
  gather_field();
  return CCNQ::Portal::content;
}

sub generic_endpoint_default {
  var template_name => 'api/endpoint';
  endpoint_default();
}

get '/provisioning/endpoint'           => sub { generic_endpoint_default };
get '/provisioning/endpoint/:endpoint' => sub { generic_endpoint_default };
get '/provisioning/endpoint/:cluster/:endpoint' => sub { generic_endpoint_default };

post '/provisioning/endpoint' => sub {
  var template_name => 'api/endpoint';
  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  # This is how we create new endpoints.
  CCNQ::Portal::Inner::Util::validate_account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $params = clean_params();

  $params->{domain} ||= CCNQ::Install::cluster_fqdn($params->{cluster});

  for my $v qw(username domain cluster account account_sub) {
    next if exists $params->{$v};
    var error => _("$v is required")_;
    var template_name => 'api/endpoint';
    return CCNQ::Portal::content;
  }

  unless($params->{password} || $params->{ip}) {
    var error => _("Either a password or an IP is required")_;
    var template_name => 'api/endpoint';
    return CCNQ::Portal::content;
  }

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update('endpoint',$params,$cv1);
  return CCNQ::Portal::Util::redirect_request($cv1);
};

get '/provisioning/endpoint_location' => sub {
  var template_name => 'api/endpoint';
  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $account = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $endpoint = params->{endpoint};
  return CCNQ::Portal::content unless $endpoint;

  my $endpoint_data = CCNQ::Portal::Inner::Util::get_endpoint($account,$endpoint);

  my $params = {
    cluster_name  => $endpoint_data->{cluster},
    username      => $endpoint_data->{username},
    domain        => $endpoint_data->{domain},
  };

  my $cv1 = AE::cv;
  CCNQ::API::api_query('endpoint_location',$params,$cv1);
  return CCNQ::Portal::Util::redirect_request($cv1);
};

'CCNQ::Portal::Inner::EndPoint';
