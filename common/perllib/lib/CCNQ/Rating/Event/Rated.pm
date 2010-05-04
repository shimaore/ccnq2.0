package CCNQ::Rating::Event::Rated;
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

use base 'CCNQ::Rating::Event';

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = shift;
  return bless $self, $class;
}

# Prevent inserting twice the same CDR by mistake.
sub id {
  my ($self) = @_;
  return join( '-',
    $self->{account},
    $self->{account_sub},
    $self->{start_date},
    $self->{start_time},
    $self->{event_type},
    ($self->{from_e164}||'none'),
    ($self->{to_e164}||'none'),
  );
}

sub compute_taxes {
  my ($self) = @_;
  $self->{taxable_cost} = $self->cost;

  # For each tax jurisdiction, compute the amount owed
  # Note: this is applied to the total cost, we don't
  #       know (yet) how to differentiate tax rates on
  #       duration_cost vs count_cost.
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

sub as_json {
  my ($self) = @_;
  return encode_json($self->as_hashref);
}

sub as_hashref {
  my ($self) = @_;
  $self->cleanup;
  return { %$self, _id => $self->id };
}

'CCNQ::Rating::Event::Rated';
