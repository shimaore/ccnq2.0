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

# Alternatively to using a Trie, the data could be simply stored in CouchDB
# and retrieved using the following algorithm:
# - query for /$table/_all_docs with parameters:
#      include_docs=true       # to get the data at the same time
#      descending=true
#      startkey=$query_string
#      limit=1
#   (meaning: "find the prefix immediately before or equal to this query_string".)
# - if the id returned is a prefix of the query_string
#   (i.e. $id = substr($query_string,0,length($id)))
#   then we found the longest prefix, and the data is available.
# - otherwise, no match found.

sub new {
  my $this = shift;
  my $name = shift;
  my $self = {
    name => $name,
    db => couchdb($name),
  };
  return bless $self;
}

sub db {
  return $_[0]->{db};
}

=head1 $table->insert(\%data)

The parameters must at least contain one field named "prefix" which
is used as the key for the record.

=cut

sub insert {
  my ($self,$data) = @_;
  $data->{_id} = $data->{prefix};
  my $update = $self->db->save_doc($data);
  CCNQ::CouchDB::receive($update);
}

=head1 lookup($key)

Returns a hashref of values associated with the longest match for the prefix.

=cut

sub lookup {
  my ($self,$key) = @_;
  # - query for /$table/_all_docs with parameters:
  #      include_docs=true       # to get the data at the same time
  #      descending=true
  #      startkey=$query_string
  #      limit=1

  my $query = $self->db->all_docs({
    include_docs => 'true',
    descending   => 'true',
    startkey     => $key,
    limit        => 1,
  });
  my $result = CCNQ::CouchDB::receive($query);
  return undef unless $result && $result->{rows} && $result->{rows}->[0]
    && defined $result->{rows}->[0]->{id};

  my $id = $result->{rows}->[0]->{id};
  return undef unless substr($key,0,length($id)) eq $id;
  return $result->{rows}->[0]->{doc};
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
