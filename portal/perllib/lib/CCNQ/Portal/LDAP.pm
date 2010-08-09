package CCNQ::Portal::LDAP;
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

use CCNQ;
use CCNQ::Util;

use Net::LDAP;

use Logger::Syslog;

sub _get_ldap {
  my $self = shift;
  my ($ldap_pass_file) = @_;

  my $ldap_uri       = $self->ldap_uri;
  my $ldap_bind      = $self->ldap_bind;
  my $ldap_password =
    CCNQ::Util::first_line_of(CCNQ::CCN.'/'.$ldap_pass_file);

  my $ldap = Net::LDAP->new( $ldap_uri, timeout => 5 ) or error($!);
  my $mesg = $ldap->bind( $ldap_bind, password => $ldap_password );
  error($mesg->error) if $mesg->code;
  return $ldap;
}

sub get_sn
{
  my $self = shift;
  my ($email) = @_;

  my $ldap       = $self->get_ldap();
  my $ldap_base = $self->ldap_base();

  my $mesg = $ldap->search(
    base => $ldap_base,
    scope => 'one',
    attrs => ['sn'],
    filter => "(cn=${email})",
  );
  error($mesg->error),
  return undef if $mesg->code;
  my $entry = $mesg->shift_entry;
  return undef unless $entry;
  return scalar($entry->get_value('sn'));
}

1;
