package CCNQ::Portal::I18N;

use Filter::Simple;

=pod


  We use macros so that e.g.
     _("....")_
  can use the local $session to gather $session->current_locale().

=cut

# See http://www.unix.com/shell-programming-scripting/70177-perl-regex-help-matching-parentheses-2.html
# or http://search.cpan.org/dist/perl-5.10.0/pod/perl5100delta.pod#Regular_expressions

sub loc {
  return CCNQ::Portal::current_session->locale->loc(@_);
}

FILTER {
  s{_\((.*?)\)_}{ (CCNQ::Portal::I18::loc($1)) }g;
};

1;