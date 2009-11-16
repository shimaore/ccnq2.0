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


# The rating table is a generic tool to store information related to a given prefix.

# Generally speaking, a given rating table will provide two values for each
# lookup:
#   a per_unit value, provided by the table's data
#   a unit name, which is part of the table's metadata (and therefor shared by all values)
# Examples of "unit" names:
#    billing_period       for rates stored per period (e.g. to account for partial month billing of a DID)
#    minute               for rates stored per minute (as is normally the case for duration-based rates)

use Tree::Trie;
use Memoize;

memoize('new');
sub new {
  my $this = shift;
  my $self = {
    name => shift,
    trie => new Tree::Trie {deepsearch => 'prefix'},
  };
  bless $self;
  $self->load;
  return $self;
}

sub file_name {
  my ($self) = @_;
  return File::Spec->catfile(qw(),$self->name);
}

sub load {
  my ($self) = @_;
  open(my $fh, '<', $self->file_name) or die $self->file_name.": $!";
  Rating::Process::process($fh, sub {
    my ($data) = @_;
    my $prefix = delete $data->{prefix};
    $self->trie->add_data($prefix,$data);
  });
  close($fh) or die $self->file_name.": $!";
}

sub lookup {
  my ($self,$key) = @_;
  return $self->trie->lookup($key);
}

1;

__END__

Fields in results:


  country         in 'e164_to_location'
  us_state        in 'e164_to_location'

  count_cost      count-base cost
  duration_rate   duration-based rate (per minute)

  initial_duration
  increment_duration
