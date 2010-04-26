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

use Net::LDAP;

use Syslog::Logger;

#
## Open a link to the LDAP store
#
sub get_ldap
{
  my ($ldap_uri,$ldap_bind) = @_;
  open(my $pass_fh, '<', CCNQ::CCN.'/ldap.pass') or error($!);
  my $ldap_password = <$pass_fh>;
  chomp $ldap_password;
  close($pass_fh) or error($!);

  my $ldap = Net::LDAP->new( $ldap_uri, timeout => 5 ) or _error($cgi,$!);
  my $mesg = $ldap->bind( $ldap_bind, password => $ldap_password );
  error($mesg->error) if $mesg->code;
  return $ldap;
}

sub get_sn
{
  my ($ldap,$email) = @_;
  my $mesg = $ldap->search(
    base => LDAP_BASE,
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
