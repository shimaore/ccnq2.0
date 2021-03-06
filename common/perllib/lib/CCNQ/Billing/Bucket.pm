package CCNQ::Billing::Bucket;
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

use CCNQ::Install;

use CCNQ::Rating::Bucket::DB;

# Normally only one server should be part of this cluster (until we
# implementing sharding of the CDR db).

use constant::defer bucket_cluster_jid => sub {
  CCNQ::Install::make_muc_jid(CCNQ::Rating::Bucket::DB::BUCKET_CLUSTER_NAME)
};

sub _bucket_id {
  return join('/','bucket',@_);
}

use CCNQ::Billing;

=head2 update_bucket(\&)

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
  my ($params) = @_;
  return CCNQ::Billing::billing_update({
    %$params,
    profile => 'bucket',
    _id => _bucket_id($params->{name}),
  });
}

=head2 retrieve_bucket(\&)

retrieve_bucket {
  name
}

=cut

sub retrieve_bucket {
  my ($params) = @_;
  return CCNQ::Billing::billing_retrieve({
    _id => _bucket_id($params->{name})
  });
}

'CCNQ::Billing::Bucket';
