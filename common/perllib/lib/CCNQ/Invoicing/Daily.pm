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

use CCNQ::Install;
use CCNQ::AE;

use CCNQ::Invoicing::Counts;
use CCNQ::Invoicing::Summarize;

=head1 CCNQ::Invoicing::Daily

Ran out of crontab, this daily script will collect the information in the
"count" provisioning report, and generate matching CDRs.

It will also do a "bill run" for the accounts which have their bill cycle
on that day.

=cut

sub run {
  my @now = localtime();
  $now[5] += 1900;
  $now[4] += 1;

  my $year  = $now[5];
  my $month = $now[4];
  my $day   = $now[3];

  # Do both account/account_sub/profile and account/account_sub/profile/type.
  my $date = sprintf('%04d%02d%02d',$year,$month,$day);
  CCNQ::Invoicing::Counts::daily_cdr($date,3);
  CCNQ::Invoicing::Counts::daily_cdr($date,4);

  # Run the bill.
  bill_run($day,$year,$month,\&CCNQ::Invoicing::Summarize::monthly);
}

sub bill_run {
  my ($bill_cycle,$year,$month,$cb) = @_;
  # For each account which has its billing_cycle today...

  use CCNQ::Billing;
  CCNQ::Billing::billing_view({
    view => 'bill_cycle',
    _id  => [$bill_cycle],
  })->cb(sub {
    my $r = CCNQ::AE::receive(@_);

    $cb->($r->{doc},$bill_cycle,$year,$month);
  });
}

1;
