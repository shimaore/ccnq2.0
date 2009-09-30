#!/usr/bin/perl
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

print $t;