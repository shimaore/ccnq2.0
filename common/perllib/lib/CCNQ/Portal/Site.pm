package CCNQ::Portal::Site;
=pod

  base_uri
  default_locale
  security (AAA) -- which AAA method to use, etc.

=cut

sub base_uri {}

sub default_locale {
  return CCNQ::I18N::default_locale;
}

sub security {
  return new CCNQ::Portal::Auth::LDAP;
}

1;