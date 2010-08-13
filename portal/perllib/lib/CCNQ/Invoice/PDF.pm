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

# This could use Paper::Specs if the module wasn't "ALPHA" in big bold
# letters.

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
  $self->doc->pdf->text
}

sub footer {
  my $self = shift;

}

1;
