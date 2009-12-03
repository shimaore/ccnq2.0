
package Portal::Directory;

use Net::LDAP;

use constant URL_ERROR    => 'https://sotelips.net/d/?q=node/63';
use constant LDAP_BIND    => 'cn=admin,dc=sotelips,dc=net';
use constant LDAP_BASE    => 'ou=Users,dc=sotelips,dc=net';

use constant LDAP_URI     => 'ldaps://ldap.sotelips.net';

sub _error {
  my $cgi = shift;
  warn(@_);
  print($cgi->redirect(URL_ERROR));
  exit 0;
}

#
## Open a link to the LDAP store
#
sub get_ldap
{
  my $cgi = shift;
  open(my $pass_fh, '<', '/etc/ccn/ldap.pass') or _error($cgi,$!);
  my $ldap_password = <$pass_fh>;
  chomp $ldap_password;
  close($pass_fh) or _error($cgi,$!);

  my $ldap = Net::LDAP->new( LDAP_URI, timeout => 5 ) or _error($cgi,$!);
  my $mesg = $ldap->bind( LDAP_BIND, password => $ldap_password );
  _error($cgi,$mesg->error) if $mesg->code;
  return $ldap;
}

sub get_sn
{
  my $cgi = shift;
  my ($ldap,$email) = @_;
  my $mesg = $ldap->search(
    base => LDAP_BASE,
    scope => 'one',
    attrs => ['sn'],
    filter => "(cn=${email})",
  );
  warn($mesg->error),
  return undef if $mesg->code;
  my $entry = $mesg->shift_entry;
  return undef unless $entry;
  return scalar($entry->get_value('sn'));
}

1;
