package CCNQ::Portal::Auth;

=pod
  auth($login,$password)
    Method must return true iff the login/password combination
    successfully authenticated the login.
=cut

sub auth {
  die "auth()"." must be instantiated by an implementation class";
}

=pod
  auth_change($login,$password)
    Method must return true iff the password was successfully
    changed for the login.
=cut

sub auth_change {
  die "auth_change()"." must be instantiated by an implementation class";
}

=pod
  create($login,$password)
    Method must return true iff the new login was successfully registered
    and the password was assigned to it.
=cut

sub create {
  die "create()"." must be instantiated by an implementation class";
}

=pod
  _untaint_params($receiver)
    Returns an arrayref comprising of [$login,$password]
    if the fields in receiver are valid.
=cut

sub _untaint_params {
  my $self = shift;
  my ($receiver) = @_;

  my $untainter = CGI::Untaint->new($receiver->Vars);

  my $login = $untainter->extract(-as_email=>'login');
  return [undef,undef] if not defined $login;

  $login = $login->format;

  my $password = $cgi->param('password');
  return [$login,undef] if not defined $password or $password eq '';
  return [$login,$password];
}

=pod
  render_auth_prompt($renderer)
    Renders a login prompt for authentication purposes.
=cut

sub render_authenticate_prompt {
  my $self = shift;
  my ($renderer) = @_;
}

=pod
  authenticate($receveiver,$session)
    Should be called by the prompt returned by render_auth_prompt.
    Returns either a unique Portal::User, or undef (if authentication failed, etc.).

=cut

sub authenticate {
  my $self = shift;
  my ($receiver,$session) = @_;

  my $p = $self->_untaint_params($receiver);

  if($self->auth(@{$p})) {
    $session->change_user(Portal::User::load($login));
  } else {
    return undef;
  }
}


=pod
  render_change_prompt($renderer,$session)
    Renders a prompt to change authentication token (e.g. change password).
=cut

sub render_change_prompt {
  my $self = shift;
  my ($renderer,$session) = @_;

}

=pod
  change
    Should be called by the prompt returned by render_change_prompt.
    Changes the authentication token for the current Portal::User.
=cut

sub change {
  my $self = shift;
  my ($receiver,$session,$cb) = @_;

  my $p = $self->_untaint_params($receiver);

  my $user = $session->user;
  $user = CCNQ::Portal::User::load $p[0];
  $cb->(FAILED,)
  if($user) {
    $cb->(OK);
  } else {
    $cb->(FAILED);
  }
}

1;
