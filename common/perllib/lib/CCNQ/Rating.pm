package CCNQ::Rating;
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

use Math::BigFloat;

=head1 create_flat_cbef

Save a flat (non-rated) CBEF.

This is used for example to create billable events off the provisioning system.

=cut

sub create_flat_cbef {
  my ($cbef) = @_;
  rate_and_save_cbef(new CCNQ::Rating::Event($cbef));
}

sub rate_and_save_cbef {
  my ($cbef) = @_;

  my $plan = lookup_plan($cbef->account,$cbef->account_sub);

  my $rated_cbef = CCNQ::Rating::Rate::rate_cbef($cbef,$plan);

  # For each tax jurisdiction, compute the amount owed
  # Note: this is applied to the total cost, we don't
  #       know (yet) how to differentiate tax rates on
  #       duration_cost vs count_cost.
  for my $tax (@{$cbef->tax || []}) {
    for my $jurisdiction (keys %{$tax}) {
      my $rate = $tax->{$jurisdiction};
      my $tax_amount = $cbef->rounding($cbef->cost * ($rate/100.0));
      $cbef->{taxes}->{$jurisdiction} += $tax_amount;
      $cbef->{tax_amount} += $tax_amount;
    }
  }
  # Then compute the grand-total cost of the call (including taxes)
  $cbef->{total_cost} = $cbef->cost + $cbef->tax_amount;

  # Save the new (rated) CBEF...
  CCNQ::Rating::Event::save_rated_cbef($rated_cbef);

  # ...and update per account/sub-account summaries.
  # (TBD)
  update_counters($cbef->account,$cbef->account_sub,$cbef);
}

=head2 save_rated_cbef

Save a rated CBEF (as JSON).

=cut

sub save_rated_cbef {
  my ($cbef) = @_;
  my $json = encode_json($cbef->cleanup);
  # I guess this should go into the billing database or something.
}

'CCNQ::Rating';
