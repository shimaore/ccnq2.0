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
use POSIX;

our %c = ();
our %p = ();
our %t = ();
our $hmin = undef;
our $hmax = undef;

my $server = shift;
my $timestamp = shift;

my $from_subscriber = shift;
my $to_subscriber = shift;
my $account = shift;

use lib '/var/www';
use CCNQ::Proxy::Bill;
my @field_names = CCNQ::Proxy::Bill::_field_names();
my %f;
@f{@field_names} = (0..$#field_names);

my $dst_subs = $f{dst_subs};
my $src_subs = $f{src_subs};
my $f_account = $f{account};

while(<>)
{
    chomp;
    my @c = split(/\|/);
    next unless defined $c[6];
    my $h = POSIX::ceil($c[6] / 3600);
    next unless $h;
    $hmin = $h if not defined $hmin or $hmin > $h;
    $hmax = $h if not defined $hmax or $hmax < $h;

    next unless $from_subscriber eq ''
        or $c[$src_subs] =~ /${from_subscriber}/o;
    next unless $to_subscriber eq ''
        or $c[$dst_subs] =~ /${to_subscriber}/o;
    next unless $account eq '' or $c[$f_account] =~ /$account/o;

    # per-method data
    $c{$h}->{$c[0]}++;
    $t{$c[0]} = 1;
    next unless $c[0] eq 'INVITE';
    # per-response code data
    $c{$h}->{$c[4]}++;
    $t{$c[4]} = 1;
    next unless $c[4] =~ /^[2-6]\d{2}$/o;
    # call related information
    $p{$h}++;
}

our @columns = sort keys %t;

# Header
print "\t";
print join("\t", @columns, 'Calls');
print "\n";

if(defined $hmin and defined $hmax)
{
    for my $h ($hmin..$hmax)
    {
        print scalar(localtime($h*3600)), "\t";
        if( exists $c{$h} )
        {
            print join("\t", map {
                exists $c{$h}->{$_}
                ? (exists $p{$h} && $_ =~ /^[2-6]\d{2}$/)
                    ? sprintf("%d (%3.1f%%)", $c{$h}->{$_}, 100.0*$c{$h}->{$_}/$p{$h})
                    : sprintf("%d", $c{$h}->{$_})
                : ''
            } @columns);
            print "\t$p{$h}";
        }
        print "\n";
    }
}
