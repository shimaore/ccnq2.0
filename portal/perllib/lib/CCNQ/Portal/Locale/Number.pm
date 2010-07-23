package CCNQ::Portal::Locale::Number;
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

use constant normalize_number => {
  nanp => sub {
    my $n = shift;
    return undef if !defined($n);
    $n =~ s/[^+\d]//g;
    # 10-digit US number
    return "1$1" if $n =~ /^([2-9]\d{9})$/;
    # 11-digit US number
    return $1 if $n =~ /^\+?(1\d{10})$/;
    # Assume international
    return $1 if $n =~ /^\+?([2-9]\d+)$/;
    return;
  },

  fr => sub {
    my $n = shift;
    return undef if !defined($n);
    $n =~ s/[^+\d]//g;
    # full-number, properly formatted
    return $1 if $n =~ /^\+?(33[1-9]\d{8})$/;
    # 10-digits FR number
    return "33$1" if $n =~ /^0([1-9]\d{8})$/;
    # International
    return $1 if $n =~ /^00([1-9]\d+)$/;
    return $1 if $n =~ /^\+([1-9]\d+)$/;
    return;
  },
};

1;
