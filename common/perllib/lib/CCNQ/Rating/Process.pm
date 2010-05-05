package CCNQ::Rating::Process;
# Copyright (C) 2009  Stephane Alnet
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

=head1 process ($fh,$cb->(\%data))
Parse a standard-formatted CBEF file and run each entry through the
callback.

The standard format for CBEF is:
- one header line: tab-delimited list of column names
- one or more lines of tab-delimited values

=cut

use AnyEvent;

use Logger::Syslog;

sub process {
  my ($fh,$cb_line,$close_cv) = @_;
  my $headers = <$fh>;
  chomp $headers;
  my @headers = split(/\t/,$headers);
  debug("Found headers: ".join(',',@headers));

  while(1) {
    my $input = <$fh>;
    if(defined $input) {
      chomp $input;
      my @input = split(/\t/,$input);
      my $data;
      @$data{@headers} = @input;
      $cb_line->($data);
    } else {
      $close_cv->end();
      return;
    }
  }
}

1;
