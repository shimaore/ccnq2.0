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
  $self->SUPER::init(@_);

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

  $self->doc->add_page();
}

sub as_string {
  my $self = shift;
  return $self->doc->stringify;
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

sub next_line {
  my $self = shift;

  if( $self->doc->next_line_would_extend_page ) {
    $self->doc->add_page;
  } else {
    $self->doc->next_line;
  }
  $self->doc->x($self->doc->margin_left);
}

sub separator {
  $self->doc->line(
    x     => $self->doc->margin_left,
    to_x  => $self->doc->width_right,
    y     => $self->doc->y,
    to_y  => $self->doc->y,
    fill_color    => 'blue',
    stroke_color  => 'blue',
    width         => 1,
  );
  $self->doc->x($self->doc->margin_left);

}

sub print_header {
  my $self = shift;

}

sub set_fonts {
  my $self = shift;
  $self->doc->add_font('VerdanaItalic');
  $self->doc->add_font('VerdanaBold');
  $self->doc->add_font('Verdana');
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

  $self->doc->set_font('VerdanaBold',12);
  $self->doc->text(join(' ',$type,@params));
  $self->separator;
  $self->next_line;
  $self->doc->set_font('Verdana',11);

  if($type eq 'invoice') {
    my $text =
      "Account: ".$self->account .
      " - " . $self->account_data->{name};
    $self->doc->text( $text, autflow => 'on' );
    $self->next_line;

    my $text2 =
      "Your invoice of ".$self->billed .
      " for the month of: ".join('/',$self->year,$self->month);
    $self->doc->text( $text2, autoflow => 'on' );
    $self->next_line;
  }
}

sub header2 {
  my $self = shift;
  my ($type,@params) = @_;

  $self->doc->set_font('VerdanaBold',11);
  $self->doc->text(join(' ',$type,@params));
  $self->next_line;
  $self->doc->set_font('Verdana',11);
}

sub header3 {
  my $self = shift;
  my ($type,@params) = @_;

  $self->doc->set_font('VerdanaItalic',12);
  $self->doc->text(join(' ',$type,@params));
  $self->next_line;
  $self->doc->set_font('Verdana',11);
}

sub summary_record {
  my $self = shift;
  # Lays out a single CDR (generally vertically)
  my ($cdr,$param) = @_;
  defined($param) or $param = '';

  for my $currency (sort keys %$cdr) {
    my $v = $cdr->{$currency};

    if($currency eq 'count') {
      $self->doc->text("    $v $param", autoflow => 'on' );
      next;
    }
    if($currency eq 'duration') {
      $self->doc->text("    $v seconds", autoflow => 'on' );
      next;
    }
    # This is actual monetary value
    $self->doc->text("Before tax:   $v->{cost} $currency",
      align => 'right', x => $self->doc->width_right );
    $self->next_line;
    for my $jurisdiction (sort keys %{$v->{taxes}}) {
      $self->doc->text("  $jurisdiction : $v->{taxes}->{$jurisdiction} $currency",
        align => 'right', x => $self->doc->width_right );
      $self->next_line;
    }
    $self->doc->text("Total tax:    $v->{tax_amount} $currency",
      align => 'right', x => $self->doc->width_right );
    $self->next_line;
    $self->doc->text("Total amount: $v->{total_cost} $currency",
      align => 'right', x => $self->doc->width_right );
    $self->next_line;
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

  $self->separator;
  $self->next_line;
  $self->doc->text( join('|',@columns) );
  $self->next_line;
}

sub cdr_line {
  my $self = shift;
  my ($cdr) = @_;
  # Prints the record that contains the sum for this table
  # (generally the last one in the table)

  $self->doc->text( join('|',map { $cdr->{$_}||'' } @columns), autoflow => 'on' );
  $self->next_line;
}

sub summary_line {
  my $self = shift;
  my ($cdr) = @_;

  # Prints the record that contains the sum for this table
  # (generally the last one in the table)
  $self->separator;
  $self->next_line;
  $self->cdr_line({%$cdr,event_type=>'Total'});
  $self->next_line;
}

sub stop_records {
  my $self = shift;
  # Ends a table showing multiple CDRs
  $self->separator;
  $self->next_line;
}


1;
