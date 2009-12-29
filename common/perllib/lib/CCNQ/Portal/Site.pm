package CCNQ::Portal::Site;
=pod

  base_uri
  default_language
  security (AAA) -- which AAA method to use, etc.

=cut

sub base_uri {}

sub default_language {

}

sub security {
  return new CCNQ::Portal::Auth::LDAP;
}

1;