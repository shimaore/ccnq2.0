package CCNQ::Trie;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

=head1 NAME

CCNQ::Trie

=head1 SYNOPSIS

  my $trie = CCNQ::Trie->new;
  $trie->load(@prefixes);
  my $match = $trie->lookup($key);

=head1 DESCRIPTION

A simple trie implementation to locate the longest match prefix
in a set of prefixes.

=cut

=head1 METHODS

=head2 new()

Creates a new, empty trie.

=cut

sub new {
  my $class = shift; $class = ref($class) || $class;
  my $self = { content => {} };
  return bless $self, $class;
}

=head2 load(@prefixes)

Insert prefixes in the trie.

=cut

sub load {
  my $self = shift;
  for (@_) { $self->insert($_) }
}

=head2 insert($prefix)

Insert a single prefix in the trie.

=cut

sub insert {
  my ($self,$prefix) = @_;
  my $ref = $self->{content};
  for (split(//,$prefix)) {
    $ref->{$_} ||= {};
    $ref = $ref->{$_};
  }
  $ref->{'00'} = 1;
}

=head2 lookup($key)

Returns the longest prefix in the trie matching the given key.
Returns undef if no such prefix exists.

=cut

sub lookup {
  my ($self,$prefix) = @_;
  my $ref = $self->{content};
  my $longest;
  my $current = '';
  $longest = $current if exists($ref->{'00'});
  for (split(//,$prefix)) {
    last if not exists($ref->{$_});
    $ref = $ref->{$_};
    $current .= $_;
    $longest = $current if exists($ref->{'00'});
  }
  return $longest;
}

=head1 AUTHOR

Stephane Alnet <stephane@shimaore.net>

=head1 CAVEATS

Values are not stored in the trie.

=head1 SEE ALSO

Tree::Trie

=head1 COPYRIGHT

Copyright 2010, Stephane Alnet

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

=cut

'CCNQ::Trie';
