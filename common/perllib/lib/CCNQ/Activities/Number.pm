package CCNQ::Activities::Number;
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

use CCNQ::Activities::Proxy;
use CCNQ::Activities::Provisioning;
use CCNQ::Activities::Billing;
use CCNQ::Manager;

sub update_number {
  my $self = shift;
  my ($request,$name,@tasks) = @_;

  my $customer_proxy_name   = $request->{cluster} or die "Missing cluster";

  my $ingress_sbc_name = $request->{inbound_username} or die "Missing inbound_username";

  my $e164_number   = $request->{number}      or die "Missing number";

  my $endpoint_ip   = $request->{endpoint_ip} or die "Missing endpoint_ip";
  my $endpoint_name = $request->{username}    or die "Missing username";

  my $account       = $request->{account}     or die "Missing account";
  my $account_sub   = $request->{account_sub} or die "Missing account_sub";

  # Return list of activities required to complete this request.
  return (

    # 1. Save the entire request in the provisioning database
    CCNQ::Activities::Provisioning::update_number($request),

    @tasks,

    # 5. Add billing entry
    CCNQ::Activities::Billing::partial_day($request,$name),

    # 6. Mark completed
    CCNQ::Manager::request_completed(),

  );
}

sub delete_number {
  my $self = shift;
  my ($request,$name,@tasks) = @_;

  # Return list of activities required to complete this request.
  return (

    # 1. Save the entire request in the provisioning database
    CCNQ::Activities::Provisioning::delete_number($request),

    @tasks,

    # 5. Add billing entry
    CCNQ::Activities::Billing::final_day($request,$name),

    # 6. Mark completed
    CCNQ::Manager::request_completed(),

  );
}

1;
