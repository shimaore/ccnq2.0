package CCNQ::Invoice::PDF;
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

use PDF::API2::Simple;
use IO::String;

# use PDF::API2::Util;
# my %sizes = PDF::API2::Util::getPaperSizes();

use constant IN_TO_PT  => 72;
use constant CM_TO_PT  => 72/2.54;

use constant A4_WIDTH  => 21    * CM_TO_PT;
use constant A4_HEIGHT => 29.7  * CM_TO_PT;

use constant LETTER_WIDTH  =>  8.5 * IN_TO_PT;
use constant LETTER_HEIGHT => 11   * IN_TO_PT;

sub doc { $_[0]->{doc} }

sub init {
  my $self = shift;

  $self->{doc} = PDF::API2::Simple->new(
    file        => rand().'.pdf',
    # page dimensions
    width       => A4_WIDTH,
    height      => A4_HEIGHT,
    line_height => 11,
  );

  $self->header( sub { $self->header(@_) } );
  $self->footer( sub { $self->footer(@_) } );

  $self->set_margins();

  $self->set_fonts();
}

sub set_margins {
  my $self = shift;

  $self->doc->margin_left (0.1*A4_WIDTH);
  $self->doc->margin_right(0.1*A4_WIDTH);
  # Reserve two lines for the header
  $self->doc->margin_top    (0.1*A4_WIDTH+2*$self->doc->line_height);
  # Reserve two lines for the footer
  $self->doc->margin_bottom (0.1*A4_WIDTH+2*$self->doc->line_height);
}

sub print_header {
  my $self = shift;

}

sub set_fonts {
  my $self = shift;
  $self->add_font('VerdanaBold');
  $self->add_font('Verdana');
}

sub header {
  my $self = shift;

  $self->doc->set_font('Verdana',12);
  # $self->doc->pdf->text();
}

sub footer {
  my $self = shift;

}

=head1 Functions dedicated to the layout

=cut

sub header1 {
  my $self = shift;
  my ($type,@params) = @_;

  $self->doc->text("* Header: $type\n");
  $self->doc->text(join(',',@params)."\n");
  if($type eq 'invoice') {
    $self->doc->text( join('', map { "$_\n" }
      "Account: ".$self->account,
      "Account name: ".$self->account_data->{name},

      "Invoice for the month of: ".join('/',$self->year,$self->month),
      "Invoiced on: ".$self->billed,
    ) );
  }
}

sub header2 {
  my $self = shift;
  my ($type,@params) = @_;

  $self->doc->text("** Header: $type\n");
  $self->doc->text( join(',',@params)."\n" );
}

sub header3 {
  my $self = shift;
  my ($type,@params) = @_;

  $self->doc->text("*** Header: $type\n");
  $self->doc->text( join(',',@params)."\n" );
}

sub summary_record {
  my $self = shift;
  # Lays out a single CDR (generally vertically)
  my ($cdr,$param) = @_;

  for my $currency (sort keys %$cdr) {
    my $v = $cdr->{$currency};

    if($currency eq 'count') {
      $self->doc->text("$v $param\n");
      next;
    }
    if($currency eq 'duration') {
      $self->doc->text("$v seconds\n");
      next;
    }
    # This is actual monetary value
    $self->doc->text("Before tax:   $v->{cost} $currency\n");
    for my $jurisdiction (sort keys %{$v->{taxes}}) {
      $self->doc->text("  $jurisdiction : $v->{taxes}->{$jurisdiction} $currency\n");
    }
    $self->doc->text("Total tax:    $v->{tax_amount} $currency\n");
    $self->doc->text("Total amount: $v->{total_cost} $currency\n");
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

sub start_records {
  my $self = shift;
  # Start a table showing multiple CDRs
  # Generally one CDR per line

  $self->doc->line( to_x => $self->doc->x+$self->doc->effective_width*0.8 );
  $self->doc->text( join('|',@columns)."\n" );
}

sub cdr_line {
  my $self = shift;
  my ($cdr) = @_;
  # Prints the record that contains the sum for this table
  # (generally the last one in the table)

  $self->doc->text( join('|',map { $cdr->{$_}||'' } @columns)."\n" );
}

sub summary_line {
  my $self = shift;
  my ($cdr) = @_;

  # Prints the record that contains the sum for this table
  # (generally the last one in the table)
  $self->doc->line( to_x => $self->doc->x+$self->doc->effective_width*0.8 );
  $self->cdr_line({%$cdr,event_type=>'Total'});
}

sub stop_records {
  my $self = shift;
  # Ends a table showing multiple CDRs
  $self->doc->line( to_x => $self->doc->x+$self->doc->effective_width*0.8 );
}


1;
