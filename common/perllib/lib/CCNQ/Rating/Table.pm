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

use AnyEvent::CouchDB;
use CCNQ::CouchDB;
use CCNQ::Trie;

=head1 new($name)

Create a new prefix-lookup table based on the content of a CouchDB table.

=cut

sub new {
  my $this = shift; $this = ref($this) || $this;
  my $name = shift;
  my $self = {
    name => $name,
    db => couchdb($name),
  };
  return bless $self, $this;
}

sub _db {
  return $_[0]->{db};
}

sub _trie {
  my ($self,$data) = @_;
  if(!$self->{trie}) {
    my $load = $self->_db->all_docs();
    my $all_docs = CCNQ::CouchDB::receive($load);
    $self->{trie} = CCNQ::Trie->new($all_docs);
  }
  return $self->{trie};
}

=head1 $table->reload()

Reloads the internal Trie structure from the underlying CouchDB table.

=cut

sub reload {
  my ($self) = @_;
  delete $self->{trie};
}

=head1 lookup($key)

Returns a hashref of values associated with the longest match for the prefix.

=cut

sub lookup {
  my ($self,$key) = @_;
  my $match = $self->_trie->lookup($key);
  return undef if !defined($match);
  my $load = $self->_db->open_doc($match);
  return CCNQ::CouchDB::receive($load);
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
