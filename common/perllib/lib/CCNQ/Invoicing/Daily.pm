package CCNQ::Invoicing::Daily;
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

use strict; use warnings;

use DateTime;

use CCNQ::Install;
use CCNQ::AE;

use CCNQ::Invoicing::Counts;
use CCNQ::Invoicing::Summarize;

use CCNQ::Billing;

=head1 CCNQ::Invoicing::Daily

Ran out of crontab, this daily script will collect the information in the
"count" provisioning report, and generate matching CDRs.

It will also do a "bill run" for the accounts which have their bill cycle
on that day.

=cut

sub run {
  my $now = DateTime->now;

  # Do both account/account_sub/profile and account/account_sub/profile/type.
  my $date = $now->ymd('');
  my $cv1 = CCNQ::Invoicing::Counts::daily_cdr($date,3);
  CCNQ::AE::receive($cv1);
  my $cv2 = CCNQ::Invoicing::Counts::daily_cdr($date,4);
  CCNQ::AE::receive($cv2);

  # Run the bill.
  bill_run( $now,
            \&CCNQ::Invoicing::Summarize::monthly );
}

sub bill_run {
  my ($date,$cb) = @_;

  # For each account which has its billing_cycle today...
  CCNQ::Billing::billing_view({
    view => 'billing_cycle',
    _id  => [$date->day],
  })->cb(sub {
    my $r = CCNQ::AE::receive(@_);

    my $cv = $cb->($r->{doc},$date);
    # Block until this account is processed
    CCNQ::AE::receive($cv);
  });
}

1;
