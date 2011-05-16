package CCNQ::Portal::UserProfile;
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

use CCNQ::Portal;
use CCNQ::AE;

# Prefix to use in user-IDs stored in the CouchDB _users database.
# sub user_id_prefix { 'org.apache.couchdb:' } # This won't work with CCNQ2
sub user_id_prefix { '' }

sub db {
  return CCNQ::Portal::db;
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
  my $prefix = $self->user_id_prefix;
  $user_id = $prefix.$user_id unless $user_id =~ /^$prefix/;
  # Access the database to load information about the specified user.
  my $cv = $self->db->open_doc($user_id);
  my $doc = CCNQ::AE::receive($cv);
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
* is_admin - whether the user is an administrator (tier-1)
* is_sysadmin - whether the user is an administrator (tier-2/superuser)
=cut

sub update {
  my $self = shift;
  my $params = ref($_[0]) ? $_[0] : {@_};
  my $doc = $self->_load($self->{_id});
  for my $f (qw(name email default_locale portal_accounts
                is_admin is_sysadmin )) {
    $self->{$f} = $doc->{$f} = $params->{$f}
      if exists $params->{$f} && defined $params->{$f};
  }
  my $cv = $self->db->save_doc($doc);
  CCNQ::AE::receive($cv);
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

sub portal_accounts { return shift->{portal_accounts} || [] }

=pod
  is_admin
    Returns whether a user is an administrator for the portal.
=cut

sub is_admin { return shift->{is_admin} }

=pod
  is_sysadmin
    Returns whether a user is a super-administrator for the portal
=cut

sub is_sysadmin { return shift->{is_sysadmin} }

# Other (yet undocumented) options

# These are only used by CCNQ::Portal::Auth::CouchDB .
# XXX Change these to use random salt + SHA1 or other scheme.

sub verify_password {
  my ($self,$password) = @_;
  # Make sure we have two defined values to compare.
  return undef unless defined($self->{password}) && defined($password);
  # Stop if they do not match.
  return undef if $self->{password} ne $password;

  # Save the last login time.
  my $doc = $self->_load($self->{_id});
  $doc->{last_login} = time();
  my $cv = $self->db->save_doc($doc);
  CCNQ::AE::receive($cv);

  # Return success.
  return 1;
}

sub change_password {
  my ($self,$password) = @_;
  return undef if !defined($password);

  my $doc = $self->_load($self->{_id});
  $doc->{password} = $password;
  my $cv = $self->db->save_doc($doc);
  CCNQ::AE::receive($cv);
}

'CCNQ::Portal::UserProfile';
