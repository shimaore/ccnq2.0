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
    line_height => 12, # 12 point for 12/11 point font
  );

  $self->doc->header( sub { $self->header(@_) } );
  $self->doc->footer( sub { $self->footer(@_) } );

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

  $self->doc->margin_left (0.1*$self->doc->width);
  $self->doc->margin_right(0.1*$self->doc->width);
  # Reserve two lines for the header
  $self->doc->margin_top    (4*$self->doc->line_height);
  # Reserve two lines for the footer
  $self->doc->margin_bottom (4*$self->doc->line_height);
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
  my $self = shift;
  my $extra = 0;
  if(@_) {
    $extra = $self->doc->text(@_);
  }

  my $strokecolor = $self->doc->strokecolor;

  $self->doc->stroke_color( $self->separator_color );

  $self->doc->line(
    x     => $self->doc->margin_left+$extra+2,
    to_x  => $self->doc->width_right,
    y     => $self->doc->y,
    to_y  => $self->doc->y,
    stroke => 'on',
    fill   => 'off',
    width  => 0.5,
  );
  $self->doc->x($self->doc->margin_left);

  $self->doc->strokecolor( $strokecolor );
}

sub set_fonts {
  my $self = shift;
  $self->doc->add_font('VerdanaItalic');
  $self->doc->add_font('VerdanaBold');
  $self->doc->add_font('Verdana');
}

sub separator_color { '#20c020' }
sub header_color    { '#208020' }

sub header {
  my $self = shift;

  $self->doc->set_font('Verdana',12);

  my $strokecolor = $self->doc->strokecolor;

  $self->doc->stroke_color( $self->header_color );

  my $text = $self->account . " - " . join('/',$self->year,$self->month);
  $self->doc->text( $text,
    x => $self->doc->width_right,
    y => $self->doc->height-3*$self->doc->line_height,
    align => 'right',
  );

  $self->doc->line(
    x    => $self->doc->margin_left,
    to_x => $self->doc->width_right,
    y    => $self->doc->height-$self->doc->margin_top,
    to_y => $self->doc->height-$self->doc->margin_top,
    stroke => 'on',
    fill => 'off',
    width => 2 );

  $self->doc->y( $self->doc->height - 6*$self->doc->line_height );

  $self->doc->strokecolor( $strokecolor );
}

sub footer {
  my $self = shift;

  my $fillcolor = $self->doc->fill_color;
  my $font = $self->doc->current_font;
  my $strokecolor = $self->doc->strokecolor;

  $self->doc->stroke_color( $self->header_color );
  $self->doc->fill_color( '#555555' );

  $self->{page_num}++;

  $self->doc->set_font( 'Verdana', 11 );
  $self->doc->text( 'Page ' . $self->{page_num},
    x => $self->doc->width_right,
    y => 3*$self->doc->line_height,
    align => 'right',
  );

  $self->doc->line(
    x    => $self->doc->margin_left,
    to_x => $self->doc->width_right,
    y    => $self->doc->margin_bottom,
    to_y => $self->doc->margin_bottom,
    stroke => 'on',
    fill => 'off',
    width => 2 );

  $self->doc->fill_color( $fillcolor );
  $self->doc->current_font( $font );
  $self->doc->strokecolor( $strokecolor );
}

=head1 Functions dedicated to the layout

=cut

sub header1 {
  my $self = shift;
  my ($type,@params) = @_;

  $self->next_line;
  $self->doc->set_font('VerdanaBold',12);
  $self->separator(join(' ',$type,@params));
  $self->next_line;
  $self->doc->set_font('Verdana',11);

  my $text = $self->loc("Account [_1] - [_2]",
    $self->account,
    $self->account_data->{name},
  );
  $self->doc->text( $text, autflow => 'on' );
  $self->next_line;

  my $billed = DateTime->new(
    year  => substr($self->billed,0,4),
    month => substr($self->billed,4,2),
    day   => substr($self->billed,6,2),
  );
  my $text2 = $self->loc("Your invoice dated [date,_1] for the month of [_2]",
    $billed,
    join('/',$self->year,$self->month),
  );
  $self->doc->text( $text2, autoflow => 'on' );
  $self->next_line;
}

sub header2 {
  my $self = shift;
  my (@params) = @_;

  $self->next_line;
  $self->doc->set_font('VerdanaBold',11);
  $self->separator(join(' ',@params));
  $self->next_line;
  $self->doc->set_font('Verdana',11);
}

sub header3 {
  my $self = shift;
  my ($type,@params) = @_;

  $self->next_line;
  $self->doc->set_font('VerdanaItalic',12);
  $self->separator(join(' ',$type,@params));
  $self->next_line;
  $self->doc->set_font('Verdana',11);
}

sub summary_record {
  my $self = shift;
  # Lays out a single CDR (generally vertically)
  my ($cdr,$param) = @_;
  defined($param) or $param = '';

  my $monetary_records = grep {
    !/^(duration|count)$/ && $cdr->{$_}->{total_cost}
  } keys %$cdr;

  $cdr->{duration} || $cdr->{count} || $monetary_records
    or return;

  $self->header3($param);

  if($cdr->{duration}) {
    $self->doc->x($self->doc->margin_left+0.07*$self->doc->effective_width);
    $self->doc->text($self->loc('[duration,_1]',$cdr->{duration}));
  }

  if($cdr->{count} && $cdr->{count} != 1) {
    $self->doc->x($self->doc->margin_left+0.40*$self->doc->effective_width);
    $self->doc->text($self->loc('[_1] units',sprintf("%0.4f",$cdr->{count})));
  }

  $self->monetary_record($cdr);
}

sub monetary_record_entry {
  my $self = shift;
  my ($label,$amount,$currency) = @_;

  $self->doc->x($self->doc->margin_left+0.74*$self->doc->effective_width);
  $self->doc->text($self->loc($label));
  $self->doc->text(
    $self->loc("[amount,_1,_2]",$amount,$currency),
    align => 'right', x => $self->doc->width_right );
  $self->next_line;
}

sub monetary_record {
  my $self = shift;
  my ($cdr) = @_;

  for my $currency (sort keys %$cdr) {
    next if $currency eq 'count' || $currency eq 'duration';

    use bignum;
    my $v = $cdr->{$currency};

    # This is actual monetary value
    next unless $v->{total_cost};
    $self->monetary_record_entry("Before tax",$v->{cost},$currency);

    for my $jurisdiction (sort keys %{$v->{taxes}}) {
      $self->monetary_record_entry($jurisdiction,$v->{taxes}->{$jurisdiction},$currency);
    }

    $self->monetary_record_entry("Total tax"   ,$v->{tax_amount},$currency);
    $self->monetary_record_entry("Total amount",$v->{total_cost},$currency);
  }
}

sub start_records {
  my $self = shift;
  # Start a table showing multiple CDRs
  # Generally one CDR per line

  $self->doc->set_font('Verdana',10);
  $self->separator;
  $self->next_line;
  $self->doc->x($self->doc->margin_left+0.07*$self->doc->effective_width);
  $self->doc->text( $self->loc('duration') );
  $self->doc->x($self->doc->margin_left+0.30*$self->doc->effective_width);
  $self->doc->text( $self->loc('count') );

  $self->doc->x($self->doc->margin_left+0.60*$self->doc->effective_width);
  $self->doc->text( $self->loc('cost') );
  $self->doc->x($self->doc->margin_left+0.72*$self->doc->effective_width);
  $self->doc->text( $self->loc('tax amount') );
  $self->doc->x($self->doc->margin_left+0.84*$self->doc->effective_width);
  $self->doc->text( $self->loc('total cost') );

  $self->next_line;
}

use DateTime;
use DateTime::Duration;

sub cdr_line {
  my $self = shift;
  my ($cdr) = @_;
  # Prints the record that contains the sum for this table
  # (generally the last one in the table)

  $self->doc->set_font('Verdana',10);
  $self->doc->x($self->doc->margin_left+0.00*$self->doc->effective_width);
  if($cdr->{start_date} && $cdr->{start_time}) {
    my $datetime = DateTime->new(
      year    => substr($cdr->{start_date},0,4),
      month   => substr($cdr->{start_date},4,2),
      day     => substr($cdr->{start_date},6,2),
      hour    => substr($cdr->{start_time},0,2),
      minute  => substr($cdr->{start_time},2,2),
      second  => substr($cdr->{start_time},4,2),
    );
    $self->doc->text(
      $self->loc("[date,_1] [time,_1]",$datetime,$datetime)." ".
      $self->loc($cdr->{event_type})
    );
  } else {
    $self->doc->text(
      $self->loc($cdr->{event_type})
    );
  }
  $self->doc->x($self->doc->margin_left+0.70*$self->doc->effective_width);
  if($cdr->{from_e164} || $cdr->{to_e164}) {
    $self->doc->text("$cdr->{from_e164} -> $cdr->{to_e164}");
  }
  $self->next_line;

  if($cdr->{total_cost}) {
    $self->doc->x($self->doc->margin_left+0.60*$self->doc->effective_width);
    $self->doc->text($self->loc("[amount,_1]",$cdr->{cost}));
    $self->doc->x($self->doc->margin_left+0.72*$self->doc->effective_width);
    $self->doc->text($self->loc("[amount,_1]",$cdr->{tax_amount}));
    $self->doc->x($self->doc->margin_left+0.84*$self->doc->effective_width);
    $self->doc->text($self->loc("[amount,_1]",$cdr->{total_cost}));
    $self->next_line;
  }

  if($cdr->{duration}) {
    use bignum;
    $self->doc->x($self->doc->margin_left+0.07*$self->doc->effective_width);
    $self->doc->text($self->loc("[duration,_1]",$cdr->{duration}));
  }

  if($cdr->{count} && $cdr->{count} != 1) {
    use bignum;
    $self->doc->x($self->doc->margin_left+0.30*$self->doc->effective_width);
    $self->doc->text(sprintf("%0.4f",$cdr->{count}));
  }

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
