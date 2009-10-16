#!/usr/bin/perl
# (c) 2006-2008 Stephane Alnet
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

our %dests;
our %dates;
our %count;

while(my $name = shift)
{
    my ($date) = ($name =~ /^(\d{8})/);
    
    open(my $fh,'<',$name) or die $!;
    my $state = 0;
    while(<$fh>)
    {
        my ($date,$hour,$seconds,$account,$dest);
        warn($_), next
            unless ($date,$hour,$seconds,$account,$dest) = /^(\d{8})(\d\d):\d\d:\d\d(.{6})(.{15}).{45}.{6}(.{5})$/;
        $count{$account}->{$date}->{$dest} += $seconds;
        $dests{$dest} = 1;
        $dates{$date} = 1;
    }
}

my @dests = sort keys %dests; undef %dests;
my @dates = sort keys %dates; undef %dates;

use POSIX;

for my $account (sort keys %count)
{
    print "Account $account\n";
    print join("\t",'',@dests),"\n";
    for my $date (@dates)
    {
        print("$date\n"), next
            unless exists $count{$account}->{$date};
        my %values = %{$count{$account}->{$date}};
        my @values = @values{@dests};
        print join("\t",$date,map { defined $_ ? POSIX::ceil($_ / 6.0) / 10.0 : 0 } @values),"\n";
    }
    print "\f";
}

