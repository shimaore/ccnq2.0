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

use CCNQ::Portal;
use AnyEvent::CouchDB;
use CCNQ::CouchDB;

sub db {
  return couchdb(CCNQ::Portal::portal_db);
}

# Class method: load an existing user from the database.
=head1
load

  CCNQ::Portal::UserProfile->load($user_id)

=cut

sub load {
  my $class = shift;
  my ($user_id) = @_;
  my $doc = $class->_load($user_id);
  return bless $doc, $class;
}

sub _load {
  my $self = shift;
  my ($user_id) = @_;
  # Access the database to load information about the specified user.
  my $cv = $self->db->open_doc($user_id);
  my $doc = CCNQ::CouchDB::receive($cv);
  return $doc || { _id => $user_id };
}

=pod
  $profile->update( name => $name, email => $email, ... )
  $profile->update( { name => $name, email => $email, ... })

Valid fields are:
* name - the user's complete name
* email - the user's email address
* default_locale - the user's preferred locale
* portal_accounts - list of accounts the user has access to
* password - the user's password (when using CCNQ::Portal::Auth::CouchDB)
  XXX we should probably store something like a random salt + SHA1 hash
=cut

sub update {
  my $self = shift;
  my $params = ref($_[0]) ? $_[0] : {@_};
  my $doc = $self->_load($self->{_id});
  for my $f (qw(name email default_locale portal_accounts password)) {
    $doc->{$f} = $self->{$f} if exists $self->{$f} && defined $self->{$f};
  }
  my $cv = $self->db->save_doc($doc);
  CCNQ::CouchDB::receive($cv);
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

'CCNQ::Portal::UserProfile';
