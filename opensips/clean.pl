#!/usr/bin/perl
use strict; use warnings;

local $/;
my $t = <>;

my @available = ($t =~ m{ route \[ ([^\]]+) \] }gsx);
my %available = map { $_ => 0 } @available;
$t =~ s{ route \( ([^\)]+) \) }{
  exists($available{$1})
    ? ($available{$1}++, "route($1)") 
    : (warn("Removing unknown route($1)"),"")
}gsxe;

my @unused = grep { !$available{$_} } sort keys %available;
print q(Unused routes: ).join(', ',@unused)."\n" if @unused;