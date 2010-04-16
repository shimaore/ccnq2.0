package CCNQ::Actions::db::bucket;
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

use CCNQ::Rating::Bucket::DB;
use CCNQ::Billing::Bucket;

sub _install {
  return CCNQ::Rating::Bucket::DB::install(@_);
}

sub _session_ready {
  my ($params,$context) = @_;
  use CCNQ::XMPPAgent;
  CCNQ::XMPPAgent::_join_room($context,CCNQ::Billing::Bucket::bucket_cluster_jid);
  return;
}

=pod

replenish_bucket {
  name
  currency
  value
  account
  account_sub
}

=cut

sub replenish_bucket {
  return CCNQ::Billing::Bucket::replenish(shift->{params});
}

'CCNQ::Actions::db::bucket';
