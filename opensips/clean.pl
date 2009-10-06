#!/usr/bin/perl
# clean.pl -- merge OpenSIPS configuration fragments
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

local $/;
my $t = <>;

sub _warn { print STDERR join(' ',@_)."\n" }

my @available = ($t =~ m{ \b route \[ ([^\]]+) \] }gsx);
my %available = map { $_ => 0 } @available;
$t =~ s{ \b route \( ([^\)]+) \) }{
  exists($available{$1})
    ? ($available{$1}++, "route($1)")
    : (_warn("Removing unknown route($1)"),"")
}gsxe;

my @unused = grep { !$available{$_} } sort keys %available;
_warn( q(Unused routes: ).join(', ',@unused) ) if @unused;

my @used = grep { $available{$_} } sort keys %available;

my $route = 0;
my %route = map { $_ => ++$route } sort @used;

_warn("Found $route routes");

$t =~ s{ \b route \( ([^\)]+) \) }{ "route($route{$1})" }gsxe;
$t =~ s{ \b route \[ ([^\]]+) \] }{ "route[$route{$1}]" }gsxe;

$t .= "\n".join('', map { "# route($route{$_}) => route($_)\n" } sort keys %route);

# Macro pre-processing
my %defines = ();
$t =~ s{ \#define \s+ (\w+) \b }{ $defines{$1} = 1 }gsxe;
$t =~ s{ \#ifdef \s+ (\w+) \b (.*?) \#endifdef \s+ \1 \b }{ exists($defines{$1}) ? $2 : '' }gsxe;
$t =~ s{ \#ifnotdef \s+ (\w+) \b (.*?) \#endifnotdef \s+ \1 \b }{ exists($defines{$1}) ? '' : $2 }gsxe;

warn("Unmatched rule $1 $2") if $t =~ m{\#(ifdef|ifnotdef|endifdef|endifnotdef) \s+ (\w+) }gsx;

print $t;