package Portal::Session;

use base 'CGI::Session';

=pod
  A Portal::Session is simply a storage location for the current session.
=cut

#
## CGI::Session Parameters
#

use constant SESSION_STORE  => '/var/www/.live-data/sessions';
use constant SESSION_EXPIRY => '+15m';

use constant URL_LOGIN             => 'https://sotelips.net/d/?q=node/69';  # Login page
use constant URL_EXPIRED           => 'https://sotelips.net/d/?q=node/69&error=Session+Timeout'; # Login page with a warning about session timeout

use Logger::Syslog;

sub new {
  my $class = shift;
  my ($cgi) = @_;
  
  # Session must already exist.
  my $self = $class->SUPER::load(undef, $cgi, {Directory=>SESSION_STORE});
  if($self) {
    return [undef,$cgi->redirect(URL_EXPIRED)]
      if($self->is_expired);
    return [undef,$cgi->redirect(URL_LOGIN)]
      if($self->is_empty);
  }
  else {
    $self = $class->SUPER::new(undef, $cgi, {Directory=>SESSION_STORE});
    $self->expire(SESSION_EXPIRY);
  }

  # At this point we should always have a valid session, unless a problem
  # occurred.
  error(CGI::Session->errstr),
  return [undef,$cgi->redirect(URL_LOGIN)]
   if(!defined($self));


  return $self;
}

1;
