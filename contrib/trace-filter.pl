#!/usr/bin/perl
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

# We assume you are running the contrib/traces.sh script
# This script will locate records that pertain to a specific to / from
# combination and return a report.

# NOTE: Requires tshark 1.2 or above. (e.g. tshark/testing if using Lenny)

use strict; use warnings;

use CCNQ::Trace;

use constant usage => <<'TXT';
Usage:
    trace-filter.pl [-p] [--call-id Call-ID] [--to to-username] [--from from-username] [--days-ago days-ago]

    At least one filter must be specified.
TXT

my $call_id = undef;
my $to_user = undef;
my $from_user = undef;
my $days_ago = undef;
my $dump_packets = 0;

while(@ARGV) {
  my $option = shift(@ARGV);
  $dump_packets = 1,         next if $option eq '-p';
  $call_id   = shift(@ARGV), next if $option eq '--call-id';
  $to_user   = shift(@ARGV), next if $option eq '--to';
  $from_user = shift(@ARGV), next if $option eq '--from';
  $days_ago  = shift(@ARGV), next if $option eq '--days-ago';
  die usage;
}

use AnyEvent;
use CCNQ::Trace;

my $mcv = AnyEvent->condvar;

CCNQ::Trace::run({
    dump_packets => $dump_packets,
    call_id      => $call_id,
    to_user      => $to_user,
    from_user    => $from_user,
    days_ago     => $days_ago,
  },
  { condvar => $mcv },
  $mcv
);

use CCNQ::Portal::Formatter;
print CCNQ::Portal::Formatter::pp($mcv->recv);

__END__
