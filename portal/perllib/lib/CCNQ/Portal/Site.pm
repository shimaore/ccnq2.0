package CCNQ::Portal::Site;
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

=pod

  new( default_locale => ..., security => ... )
  new({ default_locale => ..., security => ... })

  default_locale
  security (AAA) -- which AAA method to use, etc.
  default_content
  normalize_number

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = ref($_[0]) ? shift : {@_};
  bless $self, $class;
}

sub default_locale {
  return $_[0]->{default_locale};
}

sub security {
  return $_[0]->{security};
}

sub default_content {
  return $_[0]->{default_content};
}

sub normalize_number {
  my $self = shift;
  $self->{number_locale} or die "No number locale";
  $self->{normalize_number} ||= CCNQ::Portal::Locale::Number::normalize_number->{$self->{number_locale}};
  return $self->{normalize_number} or die "Unsupported area: $self->{number_locale}";
}

1;
