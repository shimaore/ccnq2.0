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

sub language {
  shift->{language} || CCNQ::I18N::default_language;
}

sub lang {
  my $self = shift;
  $self->{lang} ||= CCNQ::I18N->get_handle($self->language);
}

sub loc {
  $self->lang->maketext(@_);
}

1;
