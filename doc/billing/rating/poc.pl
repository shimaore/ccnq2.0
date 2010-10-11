#!/usr/bin/env perl
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict; use warnings;

# We might end up with large numbers
use Math::BigFloat; # XXX : Use it

use Tree::Trie;

# Proof-of-concept rating engine

# Input data consists of two datasets:
# (a) rating table, which contains records of the form:
#     context+prefix => rate per unit
#       with: context = account number (or other identifier)
#                     + contextual information (e.g. time-of-day, call direction, etc.)
#                     (basically each "context" defines a specific rating table)
#                     (however doing intra- vs inter-state too early is not helpful)
#             prefix  = called number prefix
#             rate per unit = rate to be applied
#                     typically unit = second
# (b) cdrs to be rated, which contaisn records of the form:
#     account context+number => duration
# The algorithm is then to do:
#   step 1: lookup the rate per unit by context+number in the trie;
#   step 2: multiply duration by rate per unit, record new info.

my $rate_table = new Tree::Trie {deepsearch => 'prefix'};

print STDERR "Loading rates\n";
my $rate_count = 0;
my $rate_table_filename = shift;
open(my $fh, '<', $rate_table_filename) or die "$rate_table_filename: $!";
while(<$fh>) {
  chomp;
  my ($prefix,@data) = split(/\t/);
  $rate_table->add_data($prefix,[@data]);
  $rate_count++;
}
close($fh) or die "$rate_table_filename: $!";
print STDERR "Loaded $rate_count prefixes.\n";

while(<>) {
  chomp;
  my ($account,$number,$duration) = split;
  my $data = $rate_table->lookup_data($number);
  warn("Cannot rate number $number"), next if !$data;
  my ($destination,$rate) = @{$data};
  my $rated = $rate * $duration;
  print join("\t",$number,$duration,$destination,$rate,$rated)."\n";
}
