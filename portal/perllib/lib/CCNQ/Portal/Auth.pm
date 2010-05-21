package CCNQ::Portal::Auth;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use CCNQ::Portal::I18N;

use constant USERNAME_PARAM => 'username';
use constant PASSWORD_PARAM => 'password';

use constant MUST_BE_INSTANTIATED => ' must be instantiated by an implementation class';

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = ref($_[0]) ? shift : {@_};
  bless $self, $class;
}

=pod
  $user_id = auth($username,$password)
    Method must return $user_id iff the login/password combination
    successfully authenticated the login.
    Otherwise should return undef.
=cut

=pod
  $success = auth_change($user_id,$password)
    Method must return ['ok'] iff the password was successfully
    changed for the login.
    Otherwise returns ['error',$error_msg].
=cut

sub auth_change {
  ['error', "auth_change()".MUST_BE_INSTANTIATED];
}

=pod
  $user_id = create($username,$password, $name, $email)
    Method must return the new user_id iff the new login was successfully registered
    and the password was assigned to it.
    Otherwise must return undef.
=cut

sub create {
  ['error', "create()".MUST_BE_INSTANTIATED];
}

=pod
  _untaint_params($receiver)
    Returns an arrayref comprising of [$username,$password]
    if the fields in receiver are valid.
=cut

use CGI::Untaint;

sub _untaint_params {
  my $self = shift;
  my ($params) = @_;

  my $untainter = CGI::Untaint->new($params);

  my $username = $untainter->extract(-as_printable=>USERNAME_PARAM);
  return [undef,undef] if not defined $username;

  # $username = $username->format;

  my $password = $params->{PASSWORD_PARAM()};
  return [$username,undef] if not defined $password or $password eq '';
  return [$username,$password];
}

=pod
  authenticate($receveiver,$session)
    Should be called by the prompt returned by render_auth_prompt.
    Returns either a unique Portal::User, or undef (if authentication failed, etc.).

=cut

sub authenticate {
  my $self = shift;
  my ($params,$session) = @_;

  my $p = $self->_untaint_params($params);

  my $user_id = $self->auth(@{$p});
  if(defined($user_id)) {
    $session->start_userid($user_id);
    return ['ok',$user_id];
  } else {
    return ['error',_('Authentication failed')_];
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
  $user = CCNQ::Portal::User::load $p->[1];
=pod
  $cb->(FAILED,...);
  if($user) {
    $cb->(OK);
  } else {
    $cb->(FAILED);
  }
=cut
}

1;
