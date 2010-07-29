package CCNQ::Actions::db::provisioning;
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

use CCNQ::Provisioning;

sub _install {
  my ($params,$context) = @_;
  return CCNQ::Provisioning::install();
}

our $provisioning_room_done = 0;

sub _session_ready {
  my ($params,$context) = @_;

  my $dest = CCNQ::Provisioning::provisioning_cluster_jid;
  return if exists $context->{joined_muc}->{$dest};

  use CCNQ::XMPPAgent;
  CCNQ::XMPPAgent::_join_room($context,$dest);
  $context->{joined_muc}->{$dest} = 0;
  return;
}

sub provisioning_update {
  return CCNQ::Provisioning::provisioning_update(shift->{params});
}

sub provisioning_delete {
  return CCNQ::Provisioning::provisioning_delete(shift->{params});
}

sub provisioning_retrieve {
  return CCNQ::Provisioning::provisioning_retrieve(shift->{params});
}

sub provisioning_view {
  return CCNQ::Provisioning::provisioning_view(shift->{params});
}

'CCNQ::Actions::db::provisioning';
