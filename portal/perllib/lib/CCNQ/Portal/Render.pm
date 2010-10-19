package CCNQ::Portal::Render;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use Dancer ':syntax';
use Template;
use Encode;

use CCNQ;
use CCNQ::Portal;

set appdir => CCNQ::Portal::SRC;
set views  => path(CCNQ::Portal::SRC, 'views');
set public => path(CCNQ::Portal::SRC, 'public');

sub template_file {
  my ($view,$tokens,$options) = @_;

  $tokens ||= {};
  $tokens->{request} = Dancer::SharedData->request;
  $tokens->{params}  = Dancer::SharedData->request->params;
  if (setting('session')) {
      $tokens->{session} = Dancer::Session->get;
  }

  my $content = Dancer::Template->engine->render($view, $tokens);
  return $content;
}

=head1 ccnq_template

This is a replacement for the 'template' function provided by Dancer.
This one supports multiple view sources.

=cut

sub ccnq_template {
    my ($view, $tokens, $options) = @_;
    $options ||= {layout => 1};

    use Dancer::Config 'setting';
    my $layout = setting('layout');
    undef $layout unless $options->{layout};

    $view .= ".tt" if $view !~ /\.tt$/;

    my $view_1 = path( vars->{template_dir} || CCNQ::CCN, 'views', $view);
    my $view_2 = path(setting('views'), $view);

    $view = -r($view_1) ? $view_1 : $view_2;

    if (! -r $view) {
        my $error = Dancer::Error->new(
            code    => 404,
            message => "Page not found",
        );
        return Dancer::Response::set($error->render);
    }

    my $content = template_file($view,$tokens);
    return $content if not defined $layout;

    $layout .= '.tt' if $layout !~ /\.tt/;
    $layout = path(setting('views'), 'layouts', $layout);
    my $full_content =
      Dancer::Template->engine->render($layout,
        {%$tokens, content => $content});

    return $full_content;
}

use CCNQ::Portal::Outer::AccountSelection;

use constant DEFAULT_TEMPLATE_NAME => 'index';

=head2 default_content()

Returns the HTML content for the default site.

The Dancer variable 'error' may be used to provide an error message.
The Dancer variable 'template_name' contains the name of the template to be used.

=head2 default_content( error => $error)

Returns the HTML content for the default site, with the specified error message.

=cut

before sub {
  var ccnq_version => $CCNQ::VERSION;
  var ccnq_portal_version => $CCNQ::Portal::VERSION;
  if(CCNQ::Portal->current_session->user) {
    var user_name =>
      CCNQ::Portal->current_session->user->profile->name;
    var is_admin =>
      CCNQ::Portal->current_session->user->profile->{is_admin} || 0;
    var is_sysadmin =>
      CCNQ::Portal->current_session->user->profile->{is_sysadmin} || 0;
    var accounts =>
      sub { CCNQ::Portal::Outer::AccountSelection->available_accounts },
  }

  var lh      => sub { CCNQ::Portal->current_session->locale };
  var prefix  => prefix; # Dancer's prefix()
  var site    => CCNQ::Portal->site;
}

use constant default_content => sub {
  my %p = @_;
  var error => $p{error} if $p{error};

  my $template_name = vars->{template_name} || DEFAULT_TEMPLATE_NAME;
  my $template_params = vars;

  my $r = ccnq_template( $template_name => $template_params );
  return ref($r) ? $r : encode_utf8($r);
};

'CCNQ::Portal::Render';
