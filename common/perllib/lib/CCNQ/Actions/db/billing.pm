package CCNQ::Actions::db::billing;
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

use CCNQ::Billing;

sub _install {
  return CCNQ::Billing::install(@_);
}

sub _session_ready {
  my ($params,$context) = @_;
  use CCNQ::XMPPAgent;
  CCNQ::XMPPAgent::_join_room($context,CCNQ::Billing::billing_cluster_jid);
  return;
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
  return CCNQ::Billing::Bucket::update_bucket(shift->{params});
}

use CCNQ::Billing::Plan;

sub update_plan {
  return CCNQ::Billing::Plan::update_plan(shift->{params});
}

use CCNQ::Billing::Account;

sub update_account {
  return CCNQ::Billing::Account::update_account(shift->{params});
}

sub update_bill_recipient {
  return CCNQ::Billing::Account::update_bill_recipient(shift->{params});
}

sub delete_bill_recipient {
  return CCNQ::Billing::Account::update_bill_recipient(shift->{params});
}

sub update_account_sub {
  return CCNQ::Billing::Account::update_account_sub(shift->{params});
}

use CCNQ::Billing::Table;

sub create_table {
  return CCNQ::Billing::Table::create(shift->{params});
}

sub update_table_prefix {
  return CCNQ::Billing::Table::update_prefix(shift->{params});
}

sub delete_table_prefix {
  return CCNQ::Billing::Table::delete_prefix(shift->{params});
}

'CCNQ::Actions::db::billing';