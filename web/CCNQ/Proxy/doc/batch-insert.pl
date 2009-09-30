#!/usr/bin/perl
# Copyright (C) 2006, 2007  Stephane Alnet
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
#

#
# For more information visit http://carrierclass.net/
#

use strict; use warnings;

sub usage()
{
    print STDERR <<TXT;

    Usage:  batch-insert.pl http://server/q.pl < file.txt

    This script will take a list of <DID> <subscriber> lines and
    output a list of wget commands to insert them in the system.

TXT
}

my $url = shift or usage();

while(<>)
{
    chomp;
    s/#.*$//; s/^\s+//; s/\s+$//; s/\s+/ /g;
    next if $_ eq '';

    my ($number,$subscriber) = split;
    die if not defined $number;
    die if not defined $subscriber;

    print qq(echo -n "Inserting $number for $subscriber : "\n);
    print qq(wget --no-check-certificate --quiet -O /dev/null --progress=dot '${url}?_quick=1&_method=insert&_class=local_number&number=${number}&username=${subscriber}' && echo OK\n);
}