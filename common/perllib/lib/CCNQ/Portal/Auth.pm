package CCNQ::Portal::Auth;

=pod
  render_auth_prompt($renderer)
    Renders a login prompt for authentication purposes.
=cut

sub render_authenticate_prompt {
  my ($renderer) = @_;
}

=pod
  authenticate($receveiver,$session)
    Should be called by the prompt returned by render_auth_prompt.
    Returns either a unique Portal::User, or undef (if authentication failed, etc.).

=cut

sub authenticate {
  my ($receiver) = @_;


  if(...) {
    return new Portal::User(...);
  } else {
    return undef;
  }
}


=pod
  render_change_prompt($renderer,$session)
    Renders a prompt to change authentication token (e.g. change password).
=cut

sub render_change_prompt {
  my ($renderer,$session) = @_;

}

=pod
  change
    Should be called by the prompt returned by render_change_prompt.
    Changes the authentication token for the current Portal::User.
=cut

sub change {
  my ($receiver,$session,$cb) = @_;

  my $user = $session->user;
  $user = new CCNQ::Portal::User username => $receiver->param('username');
  $cb->(FAILED,)
  if($user) {
    $cb->(OK);
  } else {
    $cb->(FAILED);
  }
}

1;