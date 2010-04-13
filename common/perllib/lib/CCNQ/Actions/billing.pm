package CCNQ::Actions::billing;
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
use Logger::Syslog;

use CCNQ::Install; # for host_name
use CCNQ::Billing;

sub _install {
  return CCNQ::Billing::install(@_);
}

sub _session_ready {
  my ($params,$context) = @_;
  debug("Billing _session_ready");
  use CCNQ::XMPPAgent;
  CCNQ::XMPPAgent::join_cluster_room($context);
  return;
}

use CCNQ::Billing::Rating;

sub billing_entry {
  my ($params,$context) = @_;

  # Create a new CBEF entry
  return CCNQ::Billing::Rating::rate_and_save_cbef({
    %$params,
    collecting_node => CCNQ::Install::host_name,
    request_uuid    => $params->{activity},
  });
}

use CCNQ::Billing::Bucket;

=pod

update_bucket {
  name
  currency
  increment
  decimals
  cap
}

=cut

sub update_bucket {
  return CCNQ::Billing::Bucket::update(@_);
}

sub retrieve_bucket {
  return CCNQ::Billing::Bucket::retrieve(@_);
}

use CCNQ::Billing::Plan;

sub update_plan {
  return CCNQ::Billing::Plan::update(@_);
}

sub retrieve_plan {
  return CCNQ::Billing::Plan::retrieve(@_);
}

use CCNQ::Billing::Account;

sub update_account {
  return CCNQ::Billing::Account::update_account(@_);
}

sub retrieve_account {
  return CCNQ::Billing::Account::retrieve_account(@_);
}

sub update_account_sub {
  return CCNQ::Billing::Account::update_account_sub(@_);
}

sub retrieve_account_sub {
  return CCNQ::Billing::Account::retrieve_account_sub(@_);
}

use CCNQ::Billing::Table;

sub create_table {
  return CCNQ::Billing::Table::create(@_);
}

sub update_table_prefix {
  return CCNQ::Billing::Table::update_prefix(@_);
}

sub delete_table_prefix {
  return CCNQ::Billing::Table::delete_prefix(@_);
}

'CCNQ::Actions::billing';
