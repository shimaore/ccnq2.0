package CCNQ::Actions::db::provisioning;
# Copyright (C) 2009  Stephane Alnet
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

use CCNQ::Provisioning;

use CCNQ::XMPPAgent;

sub _install {
  my ($params,$context) = @_;
  return CCNQ::Provisioning::install();
}

sub _session_ready {
  my ($params,$context) = @_;

  my $dest = CCNQ::Provisioning::provisioning_cluster_jid;
  return if exists $context->{joined_muc}->{$dest};
  $context->{joined_muc}->{$dest} ||= 0;

  CCNQ::XMPPAgent::_join_room($context,$dest);
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
