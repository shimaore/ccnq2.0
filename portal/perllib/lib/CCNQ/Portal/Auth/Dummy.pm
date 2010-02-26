package CCNQ::Portal::Auth::Dummy;
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

use CCNQ::Portal::I18N;

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = shift;
  bless $self, $class;
}

sub auth
{
  my $self = shift;
  my ($username,$password) = @_;

  return undef unless defined $username and defined $password;

  my $ok = 1;
  return $ok ? $user_id : undef;
}

sub auth_change {
  my $self = shift;
  my ($user_id,$password) = @_;

  return ['error',_('Missing parameters')_] unless defined $user_id and defined $password;

  return ['ok'];
}

sub create {
  my $self = shift;
  my ($username,$password,$name,$email) = @_;

}

sub exists {
  my $self = shift;
  my ($user_id) = @_;

  return ['already'];
}

1;
