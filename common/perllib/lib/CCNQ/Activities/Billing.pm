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

sub partial_day {
  my ($request,$event_type) = @_;
  my $now = time();
  my @now = localtime($now);
  my $date = sprintf('%04d%02d%02d',$now[5]+1900,$now[4]+1,$now[3]);
  my $time = sprintf('%02d%02d%02d',$now[2],$now[1],$now[0]);
  return (
    {
      action       => 'billing_entry',
      cluster_name => 'cdr',
      params => {
        start_date  => $date,
        start_time  => $time,
        timestamp   => $time,
        account     => $request->{account},
        account_sub => $request->{account_sub},
        event_type  => $event_type,
      }
    },
  );  
}

'CCNQ::Activities::Billing';
