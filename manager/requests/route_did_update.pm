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

sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (

    # Parameters:
    #   number
    #   account
    #   account_sub
    #   (treatment type) => 'usa-cnam'@'wholesale-sbc'
    #   endpoint

    # 1. Save the entire request in the provisioning database
    {
      action => 'update',
      cluster_name => 'provisioning',
      params => {
        _id => 'route_did/'.$request->{number},
        %{$request}
      }
    },

    # 2. Route the inbound DID through the inbound-proxy
    {
      action => 'local_number/update',
      cluster_name => 'inbound-proxy',
      params => {
        number => $request->{number},
        domain => CCNQ::Install::cluster_fqdn('inbound-proxy'),
        username => 'usa-cnam',
        username_domain => CCNQ::Install::cluster_fqdn('inbound-proxy'),
        account => $request->{account},
        account_sub => $request->{account_sub},
      }
    },

    # 3. Route the inbound DID through the customer-side proxy
    {
      action => 'local_number/update',
      cluster_name => 'wholesale-proxy',
      params => {
        number => $request->{number}, # Or with transform
        domain => CCNQ::Install::cluster_fqdn('ingress-proxy','wholesale-sbc'),
        username => $request->{endpoint},
        username_domain => CCNQ::Install::cluster_fqdn('ingress-proxy','wholesale-sbc'),
        account => $request->{account},
        account_sub => $request->{account_sub},
      }
    },

    # 4. Route the DID back into the system (onnet-onnet) using the loop on the outbound-proxy
    {
      action => 'dr_rule/update',
      cluster_name => $request->{cluster_name},
      params => {
        outbound_route => 0,
        description => "Loop for $request->{number}",
        prefix => $request->{number},
        priority => 1,
        target => 'inbound-proxy',
      }
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }

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
