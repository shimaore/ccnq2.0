package CCNQ::Invoicing::Record;
# Copyright (C) 2010  Stephane Alnet
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

use base qw(CCNQ::MathContainer);

sub add_cdr {
  my ($self,$cdr) = @_;

  use Math::BigFloat;

  # Do not mix currencies.
  my $currency = $cdr->{currency};

  # Values we have to add:
  # - with monetary unit:
  #   cost
  #   taxable_cost
  #   tax_amount
  #   taxes->{$jurisdiction}
  #   total_cost
  # - without:
  #   count
  #   duration

  for my $n (qw( cost taxable_cost tax_amount total_cost )) {
    $self->{$currency}->{$n} ||= Math::BigFloat->bzero;
    $self->{$currency}->{$n} += $cdr->{$n};
  }

  if($cdr->{taxes}) {
    for my $m (keys %{$cdr->{taxes}}) {
      $self->{$currency}->{taxes}->{$m} ||= Math::BigFloat->bzero;
      $self->{$currency}->{taxes}->{$m} += $cdr->{taxes}->{$m};
    }
  }

  for my $n (qw(count duration)) {
    $self->{$n} ||= 0;
    $self->{$n} += $cdr->{$n};
  }

  return $self;
}

1;
