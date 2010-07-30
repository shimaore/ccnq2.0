package CCNQ::Activities::Billing;
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

use CCNQ::CDR;

use DateTime;

sub partial_day {
  my ($request,$event_type) = @_;
  my $now = DateTime->now( time_zone => 'local' );
  return (
    {
      action       => 'billing_entry',
      cluster_name => CCNQ::CDR::CDR_CLUSTER_NAME,
      params => {
        start_date  => $now->ymd(''),
        start_time  => $now->hms(''),
        timestamp   => $now->epoch,
        account     => $request->{account},
        account_sub => $request->{account_sub},
        event_type  => 'route_'.$event_type,
      }
    },
  );
}

sub final_day {
  my ($request,$event_type) = @_;
  my $now = DateTime->now( time_zone => 'local' );
  return (
    {
      action       => 'billing_entry',
      cluster_name => CCNQ::CDR::CDR_CLUSTER_NAME,
      params => {
        start_date  => $now->ymd(''),
        start_time  => $now->hms(''),
        timestamp   => $now->epoch,
        account     => $request->{account},
        account_sub => $request->{account_sub},
        event_type  => 'unroute_'.$event_type,
      }
    },
  );
}

'CCNQ::Activities::Billing';
