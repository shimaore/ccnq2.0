package CCNQ::Rating::Event::Rated;
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

use base qw( CCNQ::Rating::Event );

use Math::BigFloat;

sub compute_taxes {
  my ($self) = @_;
  $self->{taxable_cost} = $self->cost;

  # For each tax jurisdiction, compute the amount owed
  # Note: this is applied to the total cost, we don't
  #       know (yet) how to differentiate tax rates on
  #       duration_cost vs count_cost.
  $self->{tax_amount} = Math::BigFloat->bzero;
  for my $tax (@{$self->tax || []}) {
    for my $jurisdiction (keys %{$tax}) {
      my $rate = $tax->{$jurisdiction};
      my $tax_amount = $self->rounding($self->taxable_cost * ($rate/100.0));
      $self->{taxes}->{$jurisdiction} += $tax_amount;
      $self->{tax_amount} += $tax_amount;
    }
  }

  $self->{total_cost} = $self->taxable_cost + $self->tax_amount;
}

'CCNQ::Rating::Event::Rated';
