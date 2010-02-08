package CCNQ::Portal;
use strict; use warnings;
use base CCNQ::Object;

# Must be set by the startup code.
our $site;

# e.g.   $CCNQ::Portal::site = new CCNQ::Portal::Site({ default_locale => 'en-US', security => new CCNQ::Portal::Auth::LDAP( ... )})

sub site {
  return $site;
}

sub current_session {
  return new CCNQ::Portal::Session;
}

1;
