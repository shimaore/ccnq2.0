package CCNQ::Portal::Session;

use Dancer ':syntax';

# When using Dancer, this is a fake.
sub new {
  my $this = shift; my $class = ref($this) || $this;
  my $self = {};
  return bless $self, $class;
}

sub start {
  session user_id => shift;
  # XXX Should be configurable, and able to say "+15m".
  session expires => time() + 15 * 60;
  # Reset the locale so that the user's locale might be selected automatically.
  session locale => undef;
}

sub end {
  session user_id => undef;
  session expires => undef;
  # Keep the user's locale.
}

sub user {
  # Make sure the session hasn't expired.
  return undef if session('expires') && session('expires') > time();
  # Return the proper user object.
  return session('user_id') && new CCNQ::Portal::User(session('user_id')); 
}

sub locale {
  # Try to automatically select a locale if none has been chosen.
  if(!session->('locale')) {
    session locale => 
      # Use the user's preferred locale if one is available.
        (CCNQ::Portal::current_user && CCNQ::Portal::current_user->default_locale)
      # XXX Use the browser's preferred locales!
      # Otherwise default to the site's preferred locale.
      || CCNQ::Portal::site->default_locale;
  }
  return session('locale') && new CCNQ::Portal::Locale(session('locale'));
}

'CCNQ::Portal::Session';
