package CCNQ::Portal::User;
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

use CCNQ::Portal::UserProfile;

=pod

  new CCNQ::Portal::User $user_id

=cut

sub new {
    my $this = shift; my $class = ref($this) || $this;
    my $self = { _id => $_[0] };
    return bless $self, $class;
}

sub id {
  my $self = shift;
  return $self->{_id};
}

sub profile {
  my $self = shift;
  return $self->{_profile} ||= CCNQ::Portal::UserProfile->load($self->id);
}

1;
