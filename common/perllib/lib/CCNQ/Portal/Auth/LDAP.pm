#!/usr/bin/perl
package Portal::Login;

use strict; use warnings;

use CGI::Carp;

use CGI::Session;
use CGI::Untaint;

use Net::LDAP;

#
## LDAP Parameters
#

use constant LDAP_BASE      => 'ou=Users,dc=sotelips,dc=net';

#
## RT Parameters
#

use constant RT_BASE        => 'https://sotelips.net/rt/';

#
## Redirect URLs
#

use constant URL_INVALID_LOGIN     => 'https://sotelips.net/d/?q=node/69&error=Invalid+Login';  # Login page with a warning about invalid login
use constant URL_INVALID_PASSWORD  => 'https://sotelips.net/d/?q=node/69&error=Invalid+Password'; # Login page with a warning about invalid password
use constant URL_LOGOUT            => 'https://sotelips.net/d/?q=node/69&error=Successful+Logout'; # Logout page

sub auth
{
  my ($login,$password) = @_;

  return 0 unless defined $login and defined $password;

  # XXX: RT also has a notion of "Disabled Users" that we should (query and test) for.

  my $bind = "cn=${login},".LDAP_BASE;
  my $ldap = Net::LDAP->new( 'ldaps://ldap.sotelips.net', timeout => 5 ) or die $@;
  my $mesg = $ldap->bind( $bind, password => $password );
  my $ok = $mesg->code ? 0 : 1;
  warn($bind.':' .$mesg->error) if $mesg->code;
  $ldap->unbind;

  undef $ldap;
  undef $mesg;
  return $ok;
}

sub auth_change {
  my ($login,$password) = @_;
  
  return 0 unless defined $login and defined $password;

  my $ldap = Portal::Directory::get_ldap($cgi);

  my $bind = "cn=${email},".Portal::Directory::LDAP_BASE;

  my $result = $ldap->set_password(
    newpasswd => $password,
    user => $bind
  );
  warn('Error: '.$result->error.', code: '.$result->code);
  return $cgi->redirect(URL_CANNOT_RESET) if($result->code);

}

sub create {
  my $ldap = Portal::Directory::get_ldap($cgi);
  
  my $bind = "cn=${email},".Portal::Directory::LDAP_BASE;

  my $result = $ldap->add(
    $bind,
    attr => [
      cn => [ $name, $email ],
      objectclass => ['inetOrgPerson'],
      mail => $email,
      uid => $email,
      sn => $name,
    ]
  );
  warn("dn: $bind -> ".$result->error);
  return $cgi->redirect(URL_FAILED) if($result->code);

  $result = $ldap->set_password(
    newpasswd => $password,
    user => $bind
  );
  warn($result->error);
  return $cgi->redirect(URL_FAILED) if($result->code);
}

sub exists {
  my $ldap = Portal::Directory::get_ldap($cgi);

  # Make sure the email address does not already exist
  my $mesg = $ldap->search( base => Portal::Directory::LDAP_BASE, filter => "(cn=$email)" );
  warn($mesg->error);
  return $cgi->redirect(URL_ERROR) if $mesg->code;
  return $cgi->redirect(URL_ALREADY) if $mesg->entries;
  
}

1;
