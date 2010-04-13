package CCNQ::Actions::node::provisioning;
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

sub _session_ready {
  my ($params,$context) = @_;
  use CCNQ::XMPPAgent;
  CCNQ::XMPPAgent::join_cluster_room($context);
  return;
}

sub provisioning_update {
  my ($params,$context) = @_;
  return CCNQ::Provisioning::provisioning_update($params->{provisioning_data});
}

sub provisioning_delete {
  my ($params,$context) = @_;
  return CCNQ::Provisioning::provisioning_delete($params);
}

sub provisioning_retrieve {
  my ($params,$context) = @_;
  return CCNQ::Provisioning::provisioning_retrieve($params);
}

sub provisioning_view {
  my ($params,$context) = @_;
  return CCNQ::Provisioning::provisioning_view($params);
}

'CCNQ::Actions::node::provisioning';
