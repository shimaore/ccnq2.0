package CCNQ::Rating::Table;
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

use strict; use warnings;

# The rating table is a generic tool to store information related to a given prefix.

use CCNQ::Trie;
use Memoize;

sub new {
  my $this = shift;
  my $self = {
    trie => new CCNQ::Trie {deepsearch => 'prefix'},
  };
  return bless $self;
}

=head1 $table->insert(\%data)

The parameters must at least contain one field named "prefix" which
is used as the key for the record.

=cut

sub insert {
  my ($self,$data) = @_;
  $self->{trie}->add_data($data->{prefix} => $data);
}

=head1 load_from_file($file_name)

The default format for a flat file describing a rating table is:
- one header line: tab-delimited list of column names
- one or more lines of tab-delimited values

One column MUST be called 'prefix' and is used as the prefix key for
the values on the same line.

=cut

sub file_name {
  my ($self) = @_;
  return $self->{name} && File::Spec->catfile(qw(),$self->{name});
}

memoize('load_from_file');
sub load_from_file {
  my $self = new CCNQ::Rating::Table;
  $self->{name} = shift;
  open(my $fh, '<', $self->file_name) or die $self->file_name.": $!";
  Rating::Process::process($fh, sub { $self->insert(@_) });
  close($fh) or die $self->file_name.": $!";
  return $self;
}

=head1 lookup($key)

Returns a hashref of values associated with the longest match for the prefix.

=cut

sub lookup {
  my ($self,$key) = @_;
  return $self->{trie}->lookup_data($key);
}

1;

__END__

Example of fields in results (see CCNQ::Rating::Rate for more details):

  country         in 'e164_to_location'
  us_state        in 'e164_to_location'

  count_cost      count-base cost
  duration_rate   duration-based rate (per minute)

  initial_duration
  increment_duration
