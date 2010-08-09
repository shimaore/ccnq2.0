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

use CCNQ::XMPPAgent;

sub _install {
  return CCNQ::Billing::install(@_);
}

sub _session_ready {
  my ($params,$context) = @_;

  my $dest = CCNQ::Billing::billing_cluster_jid;
  return if exists $context->{joined_muc}->{$dest};
  $context->{joined_muc}->{$dest} ||= 0;

  CCNQ::XMPPAgent::_join_room($context,$dest);
  return;
}

use CCNQ::Billing::Bucket;

=pod

update_bucket {
  name
  use_account
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

sub update_account_sub {
  return CCNQ::Billing::Account::update_account_sub(shift->{params});
}

use CCNQ::Billing::User;

sub update_user {
  return CCNQ::Billing::User::update_user(shift->{params});
}

use CCNQ::Billing::Table;

sub create_table {
  return CCNQ::Billing::Table::create(shift->{params});
}

sub update_table_prefix {
  return CCNQ::Billing::Table::update_prefix(shift->{params});
}

sub update_table_prefix_bulk {
  return CCNQ::Billing::Table::update_prefix_bulk(shift->{params});
}

sub delete_table_prefix {
  return CCNQ::Billing::Table::delete_prefix(shift->{params});
}

'CCNQ::Actions::db::billing';
