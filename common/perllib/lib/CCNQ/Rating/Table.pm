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

# The rating table is a generic tool to store and retrieve information
# related to a given prefix.

use AnyEvent;
use CCNQ::AE;

use CCNQ::Trie;

=head1 new($name)

Create a new prefix-lookup table based on the content of a CouchDB table.

=cut

sub new {
  my $this = shift; $this = ref($this) || $this;
  my $name = shift;
  my $self = {
    name => $name,
  };
  return bless $self, $this;
}

sub db {
  return couchdb($_[0]->{name});
}

=head1 $table->load()

Loads or reloads the internal Trie structure from the underlying CouchDB table.
If the operation fails the Trie is left untouched.

=cut

sub load {
  my ($self) = @_;

  my $rcv = AE::cv;

  $self->db->all_docs()->cb(sub{
    my $all_docs = CCNQ::AE::receive(@_);
    if($all_docs) {
      $self->{trie} = CCNQ::Trie->new(
        map { $_->{key} } @{$all_docs->{rows}}
      );
    }
    $rcv->send;
  });

  return $rcv;
}

=head1 lookup($key)

Returns a hashref of values associated with the longest match for the prefix.

=cut

sub lookup {
  my ($self,$key) = @_;

  my $rcv = AE::cv;

  my $match = $self->{trie}->lookup($key);

  if(!defined($match)) {
    $rcv->send(undef);
    return $rcv;
  }

  $self->db->open_doc($match)->cb(sub{
    my $doc = CCNQ::AE::receive(@_);
    $rcv->send($doc && $doc->{result});
  });

  return $rcv;
}

=pod

Example of fields in results (see CCNQ::Rating::Rate for more details):

  country         in 'e164_to_location'
  us_state        in 'e164_to_location'

  count_cost      count-base cost
  duration_rate   duration-based rate (per minute)

  initial_duration
  increment_duration

=cut

'CCNQ::Rating::Table';
