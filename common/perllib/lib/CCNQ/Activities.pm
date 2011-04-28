package CCNQ::Activities;
# Copyright (C) 2010  Stephane Alnet
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

use CCNQ::Activities::Proxy;
use CCNQ::Activities::Provisioning;
use CCNQ::Activities::Billing;
use CCNQ::Activities::Number;
use CCNQ::Manager;

use Carp;

sub INBOUND_PROXY_NAME   { croak }
sub OUTBOUND_PROXY_NAME  { croak }

sub FORWARDING_SBC_NAME  {
  my $self = shift;
  CCNQ::Install::cluster_fqdn('forwarding-sbc');
}

sub outbound_loopback_target { croak }

sub outbound_loopback_update {
  my $self = shift;
  my ($e164_number) = @_;

  return (
    # Route the DID back into the system (onnet-onnet) using the loop on the outbound-proxy
    # (do this one early so that we bill for the first day as soon as service is available).
    CCNQ::Activities::Proxy->dr_rule_update( {
      cluster_name        => $self->OUTBOUND_PROXY_NAME,
      outbound_route      => 0,
      prefix              => $e164_number,
      priority            => 1,
      target              => $self->outbound_loopback_target,
    } ),
  );
}

sub outbound_loopback_delete {
  my $self = shift;
  my ($e164_number) = @_;

  return (
    # Route the DID back into the system (onnet-onnet) using the loop on the outbound-proxy
    # (do this one early so that we bill for the first day as soon as service is available).
    CCNQ::Activities::Proxy->dr_rule_delete( {
      cluster_name        => $self->OUTBOUND_PROXY_NAME,
      outbound_route      => 0,
      prefix              => $e164_number,
      priority            => 1,
      target              => $self->outbound_loopback_target,
    } ),
  );
}

sub inbound_route_update {
  my $self = shift;
  my ($e164_number,$account,$account_sub,$ingress_sbc_name) = @_;

  return (
    # 3. Route the inbound DID through the inbound-proxy
    CCNQ::Activities::Proxy->local_number_update( {
      cluster_name        => $self->INBOUND_PROXY_NAME,
      number              => $e164_number,
      domain              => CCNQ::Install::cluster_fqdn($self->INBOUND_PROXY_NAME),
      username            => $ingress_sbc_name,
      username_domain     => CCNQ::Install::cluster_fqdn($self->INBOUND_PROXY_NAME),
      account             => $account,
      account_sub         => $account_sub,
    } ),
  );
}

sub inbound_route_delete {
  my $self = shift;
  my ($e164_number) = @_;

  return (
    # 3. Unroute the inbound DID through the inbound-proxy
    CCNQ::Activities::Proxy->local_number_delete( {
      cluster_name        => $self->INBOUND_PROXY_NAME,
      number              => $e164_number,
      domain              => CCNQ::Install::cluster_fqdn($self->INBOUND_PROXY_NAME),
    } ),
  );
}

sub update_number {
  my $self = shift;
  my ($request,$name,@tasks) = @_;

  my $e164_number       = $request->{number}
    or croak "Missing number";
  my $ingress_sbc_name = $request->{inbound_username}
    or croak "Missing inbound_username";
  my $account            = $request->{account}
    or croak "Missing account";
  my $account_sub       = $request->{account_sub}
    or croak "Missing account_sub";

  return CCNQ::Activities::Number->update_number($request,$name,

    # 2. Route the DID back into the system (onnet-onnet) using the loop on the outbound-proxy
    $self->outbound_loopback_update($e164_number),

    # 3. Route the inbound DID through the inbound-proxy
    $self->inbound_route_update($e164_number,$account,$account_sub,$ingress_sbc_name),

    @tasks,

  );
}

sub delete_number {
  my $self = shift;
  my ($request,$name,@tasks) = @_;

  my $e164_number       = $request->{number}
    or croak "Missing number";
  my $ingress_sbc_name = $request->{inbound_username}
    or croak "Missing inbound_username";
  my $account            = $request->{account}
    or croak "Missing account";
  my $account_sub       = $request->{account_sub}
    or croak "Missing account_sub";

  return CCNQ::Activities::Number->delete_number($request,$name,

    # 2. Route the DID back into the system (onnet-onnet) using the loop on the outbound-proxy
    $self->outbound_loopback_delete($e164_number),

    # 3. Route the inbound DID through the inbound-proxy
    $self->inbound_route_delete($e164_number,$account,$account_sub,$ingress_sbc_name),

    @tasks,

  );
}

sub update_route {
  my $self = shift;
  my ($request,$name,$national_number,@tasks) = @_;

  my $customer_proxy_name  = $request->{cluster}
    or croak "Missing cluster";
  my $username_domain = $request->{username_domain} || CCNQ::Install::cluster_fqdn($customer_proxy_name);
  my $endpoint_name = $request->{username}
    or croak "Missing username";

  # Return list of activities required to complete this request.
  return $self->update_number($request,$name,

    # 4. Route the inbound DID through the customer-side proxy
    CCNQ::Activities::Proxy->local_number_update ({
      %{$self->forwarding($request)},
      cluster_name        => $customer_proxy_name,
      number              => $national_number,
      domain              => CCNQ::Install::cluster_fqdn($customer_proxy_name),
      username            => $endpoint_name,
      username_domain     => $username_domain,
    }),

    @tasks,

  );
}

sub delete_route {
  my $self = shift;
  my ($request,$name,$national_number,@tasks) = @_;

  my $customer_proxy_name  = $request->{cluster}
    or croak "Missing cluster";
  my $username_domain = $request->{username_domain} || CCNQ::Install::cluster_fqdn($customer_proxy_name);
  my $endpoint_name = $request->{username}
    or croak "Missing username";

  # Return list of activities required to complete this request.
  return $self->delete_number($request,$name,

    # 4. Route the inbound DID through the customer-side proxy
    CCNQ::Activities::Proxy->local_number_delete ({
      %{$self->forwarding($request)},
      cluster_name        => $customer_proxy_name,
      number              => $national_number,
      domain              => CCNQ::Install::cluster_fqdn($customer_proxy_name),
      username            => $endpoint_name,
      username_domain     => $username_domain,
    }),

    @tasks,

  );
}

sub forwarding {
  my $self = shift;
  my ($request) = @_;

  my $forwarding_data = {};

  for my $i (qw(cfa cfnr cfda cfb)) {
    my $n = $i.'_number';
    my $m = $i.'_mode';

    $request->{$n}
      or next;

    my $forwarding_sbc_name = $self->FORWARDING_SBC_NAME($request->{$m});
    my $forwarding_uri = sub { 'sip:'.$request->{$n}.'@'.$forwarding_sbc_name.';account='.$request->{account}.';account_sub='.$request->{account_sub} };

    $forwarding_data->{$i} = $forwarding_uri->();

    my $t = $i.'_timeout';
    $forwarding_data->{$t} = $request->{$t}
      if exists $request->{$t} && defined $request->{$t};
  }
  return $forwarding_data;
}

1;
