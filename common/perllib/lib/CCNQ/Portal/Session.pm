package CCNQ::Portal::Session;

use base 'CGI::Session';
use Logger::Syslog;

=pod
  A Portal::Session is simply a storage location for the current session.
=cut

use constant LOCALE_PARAM => 'locale';

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

  $self->init_locale();
  return $self;
}

sub init_locale {
  my $self = shift;
  $self->change_locale( $self->param(LOCALE_PARAM)
    || ($self->user && $self->user->default_locale)
    # XXX Use the browser's preferred locales!
    || $self->site->default_locale
  );
}

sub site { shift->{_site} }
sub user { shift->{_user} }
sub current_locale { shift->{_locale} }

=pod
  change_user($user)
    Set the current session's user to a new CCNQ::Portal::User
=cut

sub change_user {
  my ($self,$user) = @_;
  $self->{_user} = $user;
  $self->init_locale();
}

=pod
  change_locale
    Used e.g. when the user manually selects a locale in
    the UI.
=cut

sub change_locale {
  my ($self,$locale) = @_;
  $self->{_locale} = $locale;
  $self->param(LOCALE_PARAM,$locale);
  $self->flush();
}

sub lang {
  my $self = shift;
  $self->{_lang} ||= CCNQ::I18N->get_handle($self->current_locale);
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
