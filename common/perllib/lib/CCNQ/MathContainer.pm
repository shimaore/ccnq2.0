package CCNQ::MathContainer;
# Copyright (C) 2010  Stephane Alnet
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

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = shift || {};
  return bless $self, $class;
}

use Scalar::Util qw(blessed);
use Data::Structure::Util qw(unbless);

sub cleanup {
  my $self = shift;

  # Remove all the fields that start with _
  if(!defined($self)) {
    return undef;
  }
  if(blessed($self) && blessed($self) =~ /^Math::Big/) {
    return unbless($self->bstr());
  }
  if(UNIVERSAL::isa($self, "ARRAY")) {
    return [map { cleanup($_) } @{$self}];
  }
  if(UNIVERSAL::isa($self, "HASH")) {
    return { map { $_ => cleanup($self->{$_}) }
      grep { /^[^_]/ } keys %{$self} };
  }
  return "$self";
}

1;
