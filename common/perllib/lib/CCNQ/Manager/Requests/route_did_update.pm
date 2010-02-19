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

use CCNQ::Activities::Proxy;
use CCNQ::Activities::Provisioning;

sub run {
  my $request = shift;
  # XXX Validate the request.

  # Return list of activities required to complete this request.
  return (

    # Parameters:
    #   number
    #   account
    #   account_sub
    #   endpoint

    # treatment_type      (e.g.  'usa-cnam')
    # inbound_proxy_name  (e.g. 'inbound-proxy')
    # outbound_proxy_name (e.g. 'outbound-proxy')
    # customer_sbc_name   (e.g  'wholesale-sbc')
    # customer_proxy_name (e.g. 'wholesale-proxy')

    # 1. Save the entire request in the provisioning database
    CCNQ::Activities::Provisioning::update( {
      _id => 'number/'.$request->{number},
      type => 'route_did',
      description => 'Direct customer number routing',
      %{$request}
    } ),

    # 2. Route the inbound DID through the inbound-proxy
    CCNQ::Activities::Proxy::local_number_update( {
        %{$request},
        cluster_name => $request->{inbound_proxy_name},
        domain => CCNQ::Install::cluster_fqdn($request->{inbound_proxy_name}),
        username => $request->{treatment_type},
        username_domain => CCNQ::Install::cluster_fqdn($request->{inbound_proxy_name}),
    } ),

    # 3. Route the inbound DID through the customer-side proxy
    CCNQ::Activities::Proxy::local_number_update ( {
      %{$request},
      cluster_name => $request->{customer_proxy_name},
      number => $request->{number}, # Or with transform
      domain => CCNQ::Install::cluster_fqdn('ingress-proxy',$request->{customer_sbc_name}),
      username => $request->{endpoint},
      username_domain => CCNQ::Install::cluster_fqdn('ingress-proxy',$request->{customer_sbc_name}),
    } ),

    # 4. Route the DID back into the system (onnet-onnet) using the loop on the outbound-proxy
    CCNQ::Activities::Proxy::dr_gateway_update( {
      cluster_name => $request->{outbound_proxy_name},
      target => CCNQ::Install::cluster_fqdn($request->{inbound_proxy_name})
    } ),
    CCNQ::Activities::Proxy::dr_rule_update( {
      cluster_name => $request->{outbound_proxy_name},
      outbound_route => 0,
      description => "Loop for $request->{number}",
      prefix => $request->{number},
      priority => 1,
      target => CCNQ::Install::cluster_fqdn($request->{inbound_proxy_name}),
    } ),

    # 6. Add billing entry for the day of creation
    {
      action => 'billing_entry',
      cluster_name => 'billing',
      params => {
        start_date => today_YYMMDD,
        start_time => today_HHMMSS,
        timestamp  => today_utctime,
        account => $request->{account},
        account_sub => $request->{account_sub},
        event_type => CCNQ::Rating::Event::EVENT_TYPE_ROUTE_DID,
        event_description => "Usage $request->{number}",
      }
    },

  );
}

'CCNQ::Manager::Requests::route_did_update';
