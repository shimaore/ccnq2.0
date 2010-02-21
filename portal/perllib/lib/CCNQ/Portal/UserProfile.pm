package CCNQ::Portal::UserProfile;
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

sub db {
  XXX Returns a proper DB object
}

# Class method: load an existing user from the database.

sub load {
  my ($user_id) = @_;
  # Access the database to load information about the specified user.
  my $doc = db->open_doc($user_id)->recv;
  $doc->{_user_id} = $user_id;
  return bless $doc;
}

=pod
  $profile->update( name => $name, email => $email, default_locale => $default_locale )
  $profile->update( { name => $name, email => $email, default_locale => $default_locale })
=cut

sub update {
  my $self = shift;
  my $params = ref($_[0]) ? $_[0] : {@_};
  my $doc = db->open_doc($self->{_user_id})->recv;
  for my $f (qw(name email default_locale portal_accounts)) {
    $doc->{$f} = $self->{$f} if exists $self->{$f} && defined $self->{$f};
  }
  db->save_doc($doc)->recv;
}

=pod
  name
    Returns a human-readable name (e.g. first name and last name) for this user.
=cut

sub name { return shift->{name} }

=pod
  email
    Returns a valid SMTP email address.
=cut

sub email { return shift->{email} }

=pod
  default_locale
    Returns the name of the default (preffered) locale for this user.
=cut

sub default_locale { return shift->{default_locale} }

=pod
  portal_accounts
    Return an arrayref of authorized accounts for this portal user.
=cut

sub portal_accounts { return shift->{portal_accounts} }

1;
