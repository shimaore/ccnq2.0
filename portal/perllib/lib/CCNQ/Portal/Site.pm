package CCNQ::Portal::Site;
=pod

  new({ base_uri => ..., default_locale => ..., security => ... })

  base_uri
  default_locale
  security (AAA) -- which AAA method to use, etc.

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = shift;
  bless $self, $class;
}

sub default_locale {
  return $_[0]->{default_locale};
}

sub security {
  return $_[0]->{security};
}

1;