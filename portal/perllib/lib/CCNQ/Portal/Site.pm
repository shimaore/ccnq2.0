package CCNQ::Portal::Site;
=pod

  new( default_locale => ..., security => ... )
  new({ default_locale => ..., security => ... })

  default_locale
  security (AAA) -- which AAA method to use, etc.

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = ref($_[0]) ? shift : {@_};
  bless $self, $class;
}

sub default_locale {
  return $_[0]->{default_locale};
}

sub security {
  return $_[0]->{security};
}

1;