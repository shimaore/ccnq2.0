package CCNQ::Billing::Rating;
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

=head1 rate_and_save_cbef

Save a flat (non-rated) CBEF.

This is used for example to create billable events off the provisioning system.

=cut

use AnyEvent;

use CCNQ::Billing::Plan;
use CCNQ::Rating;

use Logger::Syslog;

sub rate_cbef {
  my ($cbef) = @_;
  my $rcv = AE::cv;
  debug("CCNQ::Billing::Rating::rate_cbef() started");

  CCNQ::Billing::Account::plan_of($cbef)->cb(sub{
    my $plan = CCNQ::AE::receive(@_);
    if($plan) {
      debug("CCNQ::Billing::Rating::rate_cbef() got plan");
      CCNQ::Rating::rate_cbef($cbef,$plan)->cb($rcv);
    } else {
      debug("CCNQ::Billing::Rating::rate_cbef() no plan");
      $rcv->send;
    }
  });
  return $rcv;
}

use CCNQ::CDR;

sub rate_and_save_cbef {
  my ($cbef) = @_;
  my $rcv = AE::cv;
  rate_cbef($cbef)->cb(sub{
    my $rated_cbef = CCNQ::AE::receive(@_);
    $rcv->send(['Rating failed']) if !$rated_cbef;

    $rated_cbef->compute_taxes();

    # Save the new (rated) CBEF...
    CCNQ::CDR::insert($rated_cbef)->cb($rcv);
  });
  return $rcv;
}

'CCNQ::Billing::Rating';
