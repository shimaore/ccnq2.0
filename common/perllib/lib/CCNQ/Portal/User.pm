package Portal::User;


=pod
  name
    Returns a human-readable name (e.g. first name and last name) for this user.
=cut

sub name;

=pod
  email
    Returns a valid SMTP email address.
=cut

sub email;

sub default_language {
  my $self = shift;
  return $self->{default_language};
}

1;
