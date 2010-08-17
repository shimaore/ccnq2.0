package CCNQ::Invoice::Text;
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

use base qw(CCNQ::Invoice);

sub header1 {
  my $self = shift;
  my ($type,@params) = @_;

  print "* Header: $type\n";
  print join(',',@params)."\n";
  if($type eq 'invoice') {
    print join('', map { "$_\n" }
      "Account: ".$self->account,
      "Account name: ".$self->account_data->{name},

      "Invoice for the month of: ".join('/',$self->year,$self->month),
      "Invoiced on: ".$self->billed,
    );
  }
}

sub header2 {
  my $self = shift;
  my ($type,@params) = @_;

  print "** Header: $type\n";
  print join(',',@params)."\n";
}

sub header3 {
  my $self = shift;
  my ($type,@params) = @_;

  print "*** Header: $type\n";
  print join(',',@params)."\n";
}

sub summary_record {
  my $self = shift;
  # Lays out a single CDR (generally vertically)
  my ($cdr,$param) = @_;

  for my $currency (sort keys %$cdr) {
    my $v = $cdr->{$currency};

    if($currency eq 'count') {
      print "$v $param\n";
      next;
    }
    if($currency eq 'duration') {
      print "$v seconds\n";
      next;
    }
    # This is actual monetary value
    print "Before tax:   $v->{cost} $currency\n";
    for my $jurisdiction (sort keys %{$v->{taxes}}) {
      print "  $jurisdiction : $v->{taxes}->{$jurisdiction} $currency\n";
    }
    print "Total tax:    $v->{tax_amount} $currency\n";
    print "Total amount: $v->{total_cost} $currency\n";
  }
}

our @columns = qw(
  count
  event_type
  start_date
  start_time
  from_e164
  to_e164
  duration
  cost
  tax_amount
  total_cost
);

use constant LINE => ("x"x30)."\n";

sub start_records {
  my $self = shift;
  # Start a table showing multiple CDRs
  # Generally one CDR per line

  print LINE;
  print join('|',@columns)."\n";
}

sub cdr_line {
  my $self = shift;
  my ($cdr) = @_;
  # Prints the record that contains the sum for this table
  # (generally the last one in the table)

  print join('|',map { $cdr->{$_} } @columns)."\n";
}

sub summary_line {
  my $self = shift;
  my ($cdr) = @_;

  # Prints the record that contains the sum for this table
  # (generally the last one in the table)
  print LINE;
  $self->cdr_line($cdr);
}

sub stop_records {
  my $self = shift;
  # Ends a table showing multiple CDRs
  print LINE;
}

1;
