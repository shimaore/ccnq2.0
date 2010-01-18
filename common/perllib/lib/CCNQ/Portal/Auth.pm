package CCNQ::Portal::Auth;

use constant USERNAME_PARAM => 'username';
use constant PASSWORD_PARAM => 'password';

=pod
  $user_id = auth($username,$password)
    Method must return a valid user_id iff the login/password combination
    successfully authenticated the login.
    Otherwise should return undef.
=cut

sub auth {
  die "auth()"." must be instantiated by an implementation class";
}

=pod
  $success = auth_change($username,$password)
    Method must return true iff the password was successfully
    changed for the login.
=cut

sub auth_change {
  die "auth_change()"." must be instantiated by an implementation class";
}

=pod
  $user_id = create($username,$password)
    Method must return the new user_id iff the new login was successfully registered
    and the password was assigned to it.
=cut

sub create {
  die "create()"." must be instantiated by an implementation class";
}

=pod
  _untaint_params($receiver)
    Returns an arrayref comprising of [$username,$password]
    if the fields in receiver are valid.
=cut

sub _untaint_params {
  my $self = shift;
  my ($receiver) = @_;

  my $untainter = CGI::Untaint->new($receiver->Vars);

  my $username = $untainter->extract(-as_email=>USERNAME_PARAM);
  return [undef,undef] if not defined $username;

  $username = $username->format;

  my $password = $cgi->param(PASSWORD_PARAM);
  return [$username,undef] if not defined $password or $password eq '';
  return [$username,$password];
}

=pod
  render_auth_prompt($renderer)
    Renders a login prompt for authentication purposes.
=cut

sub render_authenticate_prompt {
  my $self = shift;
  my ($renderer) = @_;
  $renderer->make_form( ...
    [
      USERNAME_PARAM() => {
        ...
      },
      PASSWORD_PARAM() => {
        ...
      },
    ]
  );
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

  my $user_id = $self->auth(@{$p});
  if(defined($user_id)) {
    $session->change_user(new Portal::User $user_id);
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

  # Include Captcha?

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
  $cb->(FAILED,...);
  if($user) {
    $cb->(OK);
  } else {
    $cb->(FAILED);
  }
}

1;
