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

use CCNQ::AE;

=head1 rate_and_save_cbef

Save a flat (non-rated) CBEF.

This is used for example to create billable events off the provisioning system.

=cut

use AnyEvent;

use CCNQ::Billing::Plan;
use CCNQ::Rating;
use CCNQ::Billing::Account;

use Logger::Syslog;

use CCNQ::CDR;

sub _save_cbef {
  my ($cbef) = @_;
  my $record = $cbef->as_hashref;
  return CCNQ::CDR::insert($record);
}

=head1 rate_cbef($flat_cbef)

Returns a condvar which will either:
- receive a rated cbef if the cbef could be rated;
- or receive undef otherwise.

=cut

sub rate_cbef {
  my ($flat_cbef) = @_;
  my $rcv = AE::cv;

  CCNQ::Billing::Account::plan_of($flat_cbef)->cb(sub{
    my $plan = CCNQ::AE::receive(@_);
    if($plan) {
      CCNQ::Rating::rate_cbef($flat_cbef,$plan)->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
    } else {
      $rcv->send;
    }
  });
  return $rcv;
}

=head1 save_cbef($flat_cbef)

Returns a condvar which will return once the cbef has been saved.
(The cbef will not get rated.)

=cut

sub save_cbef {
  my ($flat_cbef) = @_;
  my $cbef = new CCNQ::Rating::Event($flat_cbef);
  # Return immediately on invalid flat_cbef
  $cbef or do { my $rcv = AE::cv; $rcv->send(); return $rcv };
  return _save_cbef($cbef);
}

=head1 rate_and_save_cbef($flat_cbef)

Returns a condvar which will either:
- return the rated cbef if the cbef could be rated and was successfully saved;
- return undef otherwise.

=cut

sub rate_and_save_cbef {
  my ($flat_cbef) = @_;
  my $rcv = AE::cv;
  rate_cbef($flat_cbef)->cb(sub{
    my $rated_cbef = CCNQ::AE::receive(@_);
    return $rcv->send() if !$rated_cbef;

    debug("CCNQ::Billing::Rating::rate_and_save_cbef() compute taxes");
    $rated_cbef->compute_taxes();

    # Save the new (rated) CBEF...
    _save_cbef($rated_cbef)->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
  });
  return $rcv;
}

'CCNQ::Billing::Rating';
