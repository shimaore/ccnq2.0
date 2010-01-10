package CCNQ::Portal::Session;

use base 'CGI::Session';
use Logger::Syslog;

=pod
  A Portal::Session is simply a storage location for the current session.
=cut

use constant LANGUAGE_PARAM => 'language';

use constant SESSION_STORE  => '/var/www/.live-data/sessions';
use constant SESSION_EXPIRY => '+15m';

# Login page
use constant URL_LOGIN      => 'https://sotelips.net/d/?q=node/69';
# Login page with a warning about session timeout
use constant URL_EXPIRED    => 'https://sotelips.net/d/?q=node/69&error=Session+Timeout';

sub new {
  my $class = shift;
  my ($cgi,$user,$site) = @_;

  # Session already exists.
  my $self = $class->SUPER::load(undef, $cgi, {Directory=>SESSION_STORE});
  if($self) {
    return [undef,$cgi->redirect(URL_EXPIRED)]
      if($self->is_expired);
    return [undef,$cgi->redirect(URL_LOGIN)]
      if($self->is_empty);
  }
  # Create a brand-new session.
  else {
    $self = $class->SUPER::new(undef, $cgi, {Directory=>SESSION_STORE});
    $self->expire(SESSION_EXPIRY);
  }

  # At this point we should always have a valid session, unless a problem
  # occurred.
  error(CGI::Session->errstr),
  return [undef,$cgi->redirect(URL_LOGIN)]
   if(!defined($self));

  $self->{_user} = $user;
  $self->{_site} = $site;

  $self->init_language();
  return $self;
}

sub init_language {
  my $self = shift;
  $self->change_language( $self->param(LANGUAGE_PARAM)
    || ($self->user && $self->user->default_language)
    # XXX Use the browser's preferred languages!
    || $self->site->default_language
  );
}

sub site { shift->{_site} }
sub user { shift->{_user} }
sub current_language { shift->{_language} }

=pod
  change_user
=cut

sub change_user {
  my ($self,$user) = @_;
  $self->{_user} = $user;
  $self->init_language();
}

=pod
  change_language
    Used e.g. when the user manually selects a language in
    the UI.
=cut

sub change_language {
  my ($self,$language) = @_;
  $self->{_language} = $language;
  $self->param(LANGUAGE_PARAM,$language);
  $self->flush();
}

sub lang {
  my $self = shift;
  $self->{_lang} ||= CCNQ::I18N->get_handle($self->current_language);
}

sub loc {
  $self->lang->maketext(@_);
}

sub loc_duration {}

sub loc_timestamp {}

sub loc_date {}

sub loc_amount {
  my $self = shift;
  my ($currency,$value) = @_;
}

sub logout
{
  my $self = shift;

  $self->delete();
  $self->flush;
}

1;
