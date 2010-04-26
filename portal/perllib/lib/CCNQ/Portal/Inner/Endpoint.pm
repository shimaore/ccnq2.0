package CCNQ::Portal::Inner::Endpoint;
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

use CCNQ::Portal::Inner::Account;

use constant STATIC_ENDPOINTS_CLUSTERS_DNS_NAME  => 'static.clusters';
use constant DYNAMIC_ENDPOINTS_CLUSTERS_DNS_NAME => 'register.clusters';

use AnyEvent;
use AnyEvent::DNS;

use constant::defer clusters_for_static_endpoints => sub {
  my $dns_txt = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::txt( $dn, $cv );
    return ($cv->recv);
  };

  return [sort $dns_txt->(CCNQ::Install::cluster_fqdn(STATIC_ENDPOINTS_CLUSTERS_DNS_NAME))];
};

use constant::defer clusters_for_dynamic_endpoints => sub {
  my $dns_txt = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::txt( $dn, $cv );
    return ($cv->recv);
  };

  return [sort $dns_txt->(CCNQ::Install::cluster_fqdn(DYNAMIC_ENDPOINTS_CLUSTERS_DNS_NAME))];
};

sub endpoints_for {
  my $account = shift;
  my $cv3 = AE::cv;
  CCNQ::API::provisioning_view('report','endpoints',$account,$cv3);
  my $endpoints = CCNQ::AE::receive($cv3);
  my @endpoints = map { $_->{doc} } @{$endpoints->{rows} || []};
  return [@endpoints];
}

sub get_endpoint {
  my ($account,$endpoint) = @_;
  my $cv = AE::cv;
  CCNQ::API::provisioning_view('report','endpoints',$account,$endpoint,$cv);
  my $endpoints = CCNQ::AE::receive($cv);
  return $endpoints->{rows}->[0]->{doc} || {};
}

sub clean_params {
  my $params = {
    account       => session('account'),
  };

  for my $p (qw(
    cluster

    account
    account_sub
    username
    domain

    password
    ip
    port
    srv

    dest_domain
    strip_digit
    allow_onnet
    always_proxy_media
    forwarding_sbc
    outbound_route
    ignore_caller_outbound_route
    ignore_default_outbound_route
    check_from

  )) {
    my $v = params->{$p};
    next unless defined $v;
    $v =~ s/^\s+//; $v =~ s/^\s+$//; $v =~ s/\s+/ /g;
    next if $v eq '';
    $params->{$p} = $v;
  }

  return $params;
}

sub gather_field {
  my $params = clean_params();

  my $endpoint = $params->{endpoint};

  my $account = $params->{account};

  my $static_clusters  = clusters_for_static_endpoints;
  my $dynamic_clusters = clusters_for_dynamic_endpoints;

  my $endpoints = endpoints_for($account);
  my $account_subs = CCNQ::Portal::Inner::Account::account_subs($account);

  # Gather data for a specific endpoint if needed
  my $endpoint_data;
  if($endpoint) {
    my $cv2 = AE::cv;
    CCNQ::API::provisioning_view('report','endpoints',$account,$endpoint,$cv2);
    my $r2 = CCNQ::AE::receive($cv2) || { rows => [] };
    $endpoint_data = $r2->{rows}->[0]->{doc} || {};
  } else {
    $endpoint_data = $params;
  }

  my $is_static  = defined($endpoint_data->{cluster}) &&
    grep { $_ eq $endpoint_data->{cluster} } @$static_clusters;
  my $is_dynamic = defined($endpoint_data->{cluster}) &&
    grep { $_ eq $endpoint_data->{cluster} } @$dynamic_clusters;

  var field => {
    %$endpoint_data,
    endpoints        => $endpoints,
    account_subs     => $account_subs,
    is_static        => $is_static,
    is_dynamic       => $is_dynamic,
    static_clusters  => $static_clusters,
    dynamic_clusters => $dynamic_clusters,
  };
}

sub endpoint_default {
  return unless CCNQ::Portal->current_session->user;
  if( session('account') && session('account') =~ /^[\w-]+$/ ) {
    gather_field();
  }
  var template_name => 'api/endpoint';
  return CCNQ::Portal->site->default_content->();
}

get '/provisioning/endpoint'           => sub { endpoint_default };
get '/provisioning/endpoint/:endpoint' => sub { endpoint_default };
get '/provisioning/endpoint/:cluster/:endpoint' => sub { endpoint_default };
post '/provisioning/endpoint/select'   => sub { endpoint_default };

post '/provisioning/endpoint' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless CCNQ::Portal->current_session->user->profile->is_admin;
  # This is how we create new endpoints.
  return unless session('account');
  return unless session('account') =~ /^[\w-]+$/;

  my $params = clean_params();

  for my $v qw(username domain cluster account account_sub) {
    next if exists $params->{$v};
    var error => _("$v is required")_;
    var template_name => 'api/endpoint';
    return CCNQ::Portal->site->default_content->();
  }

  # Update the information in the API.
  my $cv1 = AE::cv;
  CCNQ::API::api_update('endpoint',$params,$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

'CCNQ::Portal::Inner::Account';
