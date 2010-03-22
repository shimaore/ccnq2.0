package CCNQ::Trie;
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

sub new {
  my $class = shift; $class = ref($class) || $class;
  my $self = { content => {} };
  return bless $self, $class;
}

sub load {
  my ($self,$data) = @_;
  for (@{$data}) { $self->insert($_) }
}

sub insert {
  my ($self,$prefix) = @_;
  my $ref = $self->{content};
  for (split(//,$prefix)) {
    $ref->{$_} ||= {};
    $ref = $ref->{$_};
  }
  $ref->{'00'} = 1;
}

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

'CCNQ::Trie';
