package CCNQ::Billing;
# Copyright (C) 2010  Stephane Alnet
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

=head1 rate_and_save_cbef

Save a flat (non-rated) CBEF.

This is used for example to create billable events off the provisioning system.

=cut

use AnyEvent;
use CCNQ::Rating;
use CCNQ::Provisioning;

sub rate_cbef {
  my ($cbef) = @_;
  my $rcv = AE::cv;
  CCNQ::Provisioning::lookup_plan($cbef->account,$cbef->account_sub)->cb(sub{
    my $plan = eval { shift->recv };
    $rcv->send($plan && CCNQ::Rating::rate_cbef($cbef,$plan));
  });
  return $rcv;
}

sub rate_and_save_cbef {
  my ($cbef) = @_;
  my $rcv = AE::cv;
  rate_cbef($cbef)->cb(sub{
    my $rated_cbef = eval { shift->recv };
    $rated_cbef->compute_taxes();

    # Save the new (rated) CBEF...
    CCNQ::Rating::Event::save_rated_cbef($rated_cbef)->cb(sub{
      eval { shift->recv };
      # ...and update per account/sub-account summaries.
      # (TBD)
      update_counters($cbef->account,$cbef->account_sub,$cbef);
    });
  });
  return $rcv;
}

=head2 save_rated_cbef

Save a rated CBEF (as JSON).

=cut

sub save_rated_cbef {
  my ($rated_cbef) = @_;
  my $json = $rated_cbef->as_json;
  # I guess this should go into the billing database or something.
}


'CCNQ::Billing';
