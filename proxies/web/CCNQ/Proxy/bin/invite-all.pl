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
use strict; 
# use warnings;
use POSIX;

my $server = shift;
my $timestamp = shift;

my $caller = shift;
my $called = shift;
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
my $from_user = $f{from_user};
my $ruri_user = $f{ruri_user};
my $to_user = $f{to_user};
my $f_account = $f{account};

# Maximum number of entries we will print out.
my $max_rows = 1000;


my @data = ();
while(<>)
{
    chomp;
    my @c = split(/\|/);
    next unless $c[0] eq 'INVITE';
    next unless $from_subscriber eq ''
        or $c[$src_subs] =~ /${from_subscriber}/o;
    next unless $to_subscriber eq ''
        or $c[$dst_subs] =~ /${to_subscriber}/o;
    next unless $caller eq '' or $c[$from_user] =~ /$caller/o;
    next unless $called eq '' or $c[$ruri_user] =~ /$called/o or $c[$to_user] =~ /$called/o;
    next unless $account eq '' or $c[$f_account] =~ /$account/o;
    push @data, [@c];
    last if $#data >= $max_rows;
}

print "Number of rows was limited to $max_rows. Data has been omitted.\n"
    if $#data >= $max_rows;
print 'Total number of rows: '.($#data+1)."\n";

my $counter = 0;
my $header_every = 10;
my $f_callid = $f{callid};
my $f_time = $f{time};

my @display_names = ('  link','timestamp','server',@field_names);
for my $l (sort { $a->[$f_time] <=> $b->[$f_time] } @data)
{
    if($counter == 0)
    {
      print join("\t",@display_names)."\n";
      $counter = $header_every;
    }
    $l->[$f_time] = scalar(localtime($l->[$f_time]));
    my $link = qq(<a href="?_class=report_call&_method=input_insert&server=${server}&timestamp=${timestamp}&callid=$l->[$f_callid]">View</a>);
    print join("\t",$link,$timestamp,$server,@{$l})."\n";
    $counter--;
}
