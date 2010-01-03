package Rating::Process;
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

=pod
  process ($fh,$cb->(\%data))
    Parse a standard-formatted CBEF file and run each entry through the
    callback.
=cut

sub process {
  my ($fh,$cb) = @_;
  my $headers = <$fh>;
  chomp $headers;
  my @headers = split(/\t/,$headers);
  my $w = new AnyEvent->io( fh => $fh, poll => 'r', cb => sub {
    my $input = <$fh>;
    return undef $w if !defined $input;
    chomp $input;
    my @input = split(/\t/,$input);
    my $data;
    @$data{@headers} = @input;
    $cb->($data);
  });
}

1;
