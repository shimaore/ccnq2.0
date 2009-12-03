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

sub logout
{
  my ($cgi,$session) = @_;

  $session->delete();
  $session->flush;
  return [undef,$cgi->redirect(URL_LOGOUT)];
}

sub check
{
  my $cgi = shift;

  my $action = $cgi->param('action');
  return login($cgi) if defined $action && $action eq 'login';

  # Session must already exist.
  my $session = CGI::Session->load(undef, $cgi, {Directory=>SESSION_STORE}) or die CGI::Session->errstr;

  return [undef,$cgi->redirect(URL_LOGIN)]
   if(!defined($session));

  return [undef,$cgi->redirect(URL_EXPIRED)]
   if($session->is_expired);
  return [undef,$cgi->redirect(URL_LOGIN)]
   if($session->is_empty);

  my $login = $session->param('logged_in');
  return [undef,$cgi->redirect(URL_INVALID_LOGIN)]
   if(!defined($login) || $login eq '');

  return logout($cgi,$session) if defined $action && $action eq 'logout';
  return [$session,''];
}

sub login
{
  my $cgi = shift or die;

  #
  ## Validate the fields
  #

  my $untainter = CGI::Untaint->new($cgi->Vars);

  my $login = $untainter->extract(-as_email=>'login');
  return [undef,$cgi->redirect(URL_INVALID_LOGIN)] if not defined $login;

  $login = $login->format;

  my $password = $cgi->param('password');
  return [undef,$cgi->redirect(URL_INVALID_PASSWORD)] if not defined $password or $password eq '';

  #
  ## Use LDAP to validate the password.
  #

  # XXX: RT also has a notion of "Disabled Users" that we should (query and test) for.

  my $bind = "cn=${login},".LDAP_BASE;
  my $ldap = Net::LDAP->new( 'ldaps://ldap.sotelips.net', timeout => 5 ) or die $@;
  my $mesg = $ldap->bind( $bind, password => $password );
  warn($bind.':' .$mesg->error),
  return [undef,$cgi->redirect(URL_INVALID_PASSWORD)] if $mesg->code;
  $ldap->unbind;

  undef $ldap;
  undef $mesg;

  #
  ## If logged in, create a CGI::Session.
  #

  my $session = new CGI::Session(undef, $cgi, {Directory=>SESSION_STORE}) or die CGI::Session->errstr;
  $session->param('logged_in', $login);
  $session->expire(SESSION_EXPIRY);

  #
  ## Create RT URL
  #

  my $rt = 
    $cgi->start_form(-action=>RT_BASE,-method=>'POST',-name=>'rt_login').
    $cgi->hidden(-name=>'user',-value=>$login,-force=>1).
    $cgi->hidden(-name=>'pass',-value=>$password,-force=>1).
    $cgi->submit('submit','>> Ticket system').
    $cgi->end_form();

  $session->param('rt',$rt);

  $session->flush();
  return [$session,''];
}

1;
