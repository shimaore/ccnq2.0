package CCNQ::Manager::Requests::route_did_update;
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

use CCNQ::Activities::Proxy;
use CCNQ::Activities::Provisioning;
use CCNQ::Manager;

sub run {
  my $request = shift;
  # XXX Validate the request.

  # Return list of activities required to complete this request.
  return (

    # Parameters:
    #   account
    #   account_sub
    #   number
    #   endpoint

    # treatment_type      (e.g.  'usa-cnam')
    # inbound_proxy_name  (e.g. 'inbound-proxy')
    # outbound_proxy_name (e.g. 'outbound-proxy')
    # customer_sbc_name   (e.g  'wholesale-sbc')
    # customer_proxy_name (e.g. 'wholesale-proxy')

    # 1. Save the entire request in the provisioning database
    CCNQ::Activities::Provisioning::update_number($request),

    # 2. Route the DID back into the system (onnet-onnet) using the loop on the outbound-proxy
    # (do this one early so that we bill for the first day as soon as service is available).
    CCNQ::Activities::Proxy->dr_gateway_update( {
      cluster_name => $request->{outbound_proxy_name},
      id => '1000',
      target => CCNQ::Install::cluster_fqdn($request->{inbound_proxy_name})
    } ),
    CCNQ::Activities::Proxy->dr_rule_update( {
      cluster_name => $request->{outbound_proxy_name},
      outbound_route => 0,
      description => ["Loop for [_1]",$request->{number}],
      prefix => $request->{number},
      priority => 1,
      target => '1000',
    } ),

    # 3. Route the inbound DID through the inbound-proxy
    CCNQ::Activities::Proxy->local_number_update( {
        %{$request},
        cluster_name => $request->{inbound_proxy_name},
        domain => CCNQ::Install::cluster_fqdn($request->{inbound_proxy_name}),
        username => $request->{treatment_type},
        username_domain => CCNQ::Install::cluster_fqdn($request->{inbound_proxy_name}),
    } ),

    # 4. Route the inbound DID through the customer-side proxy
    CCNQ::Activities::Proxy->local_number_update ( {
      %{$request},
      cluster_name => $request->{customer_proxy_name},
      number => $request->{number}, # Or with transform
      domain => CCNQ::Install::cluster_fqdn('ingress-proxy',$request->{customer_sbc_name}),
      username => $request->{endpoint},
      username_domain => CCNQ::Install::cluster_fqdn('ingress-proxy',$request->{customer_sbc_name}),
    } ),

    # 5. Add billing entry for the day of creation
    CCNQ::Activities::Billing::partial_day($request,'did'),

    # 6. Mark completed
    CCNQ::Manager::request_completed(),
  );
}

'CCNQ::Manager::Requests::route_did_update';
