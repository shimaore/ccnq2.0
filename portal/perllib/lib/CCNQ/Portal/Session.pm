package CCNQ::Portal::Session;
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

use Dancer ':syntax';
use CCNQ::Portal::Locale;
use CCNQ::Portal::User;

# When using Dancer, this is a fake.
sub new {
  my $this = shift; my $class = ref($this) || $this;
  my $self = {};
  return bless $self, $class;
}

sub start {
  my $self = shift;
  session user_id => shift;
  # XXX Should be configurable, and able to say "+15m".
  session expires => time() + 15 * 60;
  # Save the locale that might have been selected earlier.
  session old_locale => session('locale');
  # Reset the locale so that the user's locale might be selected automatically.
  session locale => undef;
  return $self;
}

sub end {
  my $self = shift;
  session user_id => undef;
  session expires => undef;
  # Keep the user's locale.
  return $self;
}

sub user {
  my $self = shift;
  # Make sure the session hasn't expired.
  return undef if session('expires') && session('expires') > time();
  # Return the proper user object.
  return session('user_id') && CCNQ::Portal::User->new(session('user_id'));
}

sub locale {
  my $self = shift;
  # Try to automatically select a locale if none has been chosen.
  if(!session('locale')) {
    session locale =>
      # Use the user's preferred locale if one is available.
        ($self->user && $self->user->default_locale)
      # Use the user's previous session's locale if one was selected.
      || session('old_locale')
      # XXX Use the browser's preferred locales!
      # Otherwise default to the site's preferred locale.
      || CCNQ::Portal->site->default_locale;
  }
  return session('locale') && CCNQ::Portal::Locale->new(session('locale'));
}

'CCNQ::Portal::Session';
