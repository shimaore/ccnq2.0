package CCNQ::Billing::Bucket;
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

use CCNQ::Billing;
use CCNQ::Rating::Bucket;

=pod

update_bucket {
  name
  currency
  increment
  decimals
  cap
}

=cut

sub update {
  my ($params) = @_;
  return CCNQ::Billing::update({
    %params,
    _id => join('/','bucket',$params->{name}),
  });
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

sub replenish {
  my ($params) = @_;
  my $bucket = CCNQ::Rating::Bucket->new($params->{name});
  return $bucket->replenish($params);
}



'CCNQ::Billing::Bucket';
