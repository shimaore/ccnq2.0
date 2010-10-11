package CCNQ::Portal::Auth::LDAP;
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
use base qw( CCNQ::Portal::Auth );

use Net::LDAP;
use CCNQ::Portal::I18N;

use Logger::Syslog;

sub auth
{
  my $self = shift;
  my ($username,$password) = @_;

  return undef unless defined $username and defined $password;

  # XXX: RT also has a notion of "Disabled Users" that we should (query and test) for.

  my $user_id = $username;

  my $bind = "cn=${user_id},".$self->ldap_base;
  my $ldap = Net::LDAP->new( $self->ldap_uri, timeout => 5 ) or die $@;
  my $mesg = $ldap->bind( $bind, password => $password );
  my $ok = $mesg->code ? 0 : 1;
  warning($bind.':' .$mesg->error) if $mesg->code;
  $ldap->unbind;

  undef $ldap;
  undef $mesg;

  return $ok ? $user_id : undef;
}

sub auth_change {
  my $self = shift;
  my ($user_id,$password) = @_;
  
  return ['error',_('Missing parameters')_] unless defined $user_id and defined $password;

  my $ldap = $self->get_ldap();

  my $bind = "cn=${user_id},".$self->ldap_base;

  my $result = $ldap->set_password(
    newpasswd => $password,
    user => $bind,
  );
  warn('Error: '.$result->error.', code: '.$result->code);
  return ['error',_('Cannot change password')_] if($result->code);
  return ['ok'];
}

sub create {
  my $self = shift;
  my ($user_id,$password,$name,$email) = @_;

  my $ldap = $self->get_ldap();

  my $bind = "cn=${user_id},".$self->ldap_base;

  my $result = $ldap->add(
    $bind,
    attr => [
      cn => [ $name, $email ],
      objectclass => ['inetOrgPerson'],
      mail => $email,
      uid => $user_id,
      sn => $name,
    ]
  );
  warn("dn: $bind -> ".$result->error);
  return undef if($result->code);

  $result = $ldap->set_password(
    newpasswd => $password,
    user => $bind,
  );
  warn($result->error);
  return undef if($result->code);
}

sub exists {
  my $self = shift;
  my ($user_id) = @_;

  my $ldap = $self->get_ldap();

  # Make sure the email address does not already exist
  my $mesg = $ldap->search( base => $self->ldap_base, filter => "(uid=$user_id)" );
  warning($mesg->error);
  return ['error',_('Internal error')_] if $mesg->code;
  return ['already'] if $mesg->entries;
  return ['not-present'];
}

1;
