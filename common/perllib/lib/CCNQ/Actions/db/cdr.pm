package CCNQ::Actions::db::cdr;
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

use CCNQ::CDR;
use CCNQ::Rating::Event::Rated;

use CCNQ::XMPPAgent;

sub _install {
  return CCNQ::CDR::install(@_);
}

sub _session_ready {
  my ($params,$context) = @_;

  my $dest = CCNQ::CDR::cdr_cluster_jid;
  return if exists $context->{joined_muc}->{$dest};
  $context->{joined_muc}->{$dest} ||= 0;

  CCNQ::XMPPAgent::_join_room($context,$dest);
  return;
}

use CCNQ::Billing::Rating;
use CCNQ::Install; # for host_name

sub billing_entry {
  my ($params,$context) = @_;

  # Create a new CBEF entry
  return CCNQ::Billing::Rating::rate_and_save_cbef({
    %{$params->{params}},
    collecting_node => CCNQ::Install::host_name,
    request_uuid    => $params->{activity},
  });
}

'CCNQ::Actions::db::cdr';
