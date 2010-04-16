package CCNQ::Portal::Render;
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

use Dancer ':syntax';
use Template;
use Encode;

use CCNQ;
use CCNQ::Portal;

set views  => path(CCNQ::Portal::SRC, 'views');
set public => path(CCNQ::Portal::SRC, 'public');

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

    my $view_1 = path(CCNQ::CCN, 'views', $view);
    my $view_2 = path(setting('views'), $view);

    $view = -r($view_1) ? $view_1 : $view_2;

    if (! -r $view) {
        my $error = Dancer::Error->new(
            code    => 404,
            message => "Page not found",
        );
        return Dancer::Response::set($error->render);
    }

    $tokens ||= {};
    $tokens->{request} = Dancer::SharedData->request;
    $tokens->{params}  = Dancer::SharedData->request->params;
    if (setting('session')) {
        $tokens->{session} = Dancer::Session->get;
    }

    my $content = Dancer::Template->engine->render($view, $tokens);
    return $content if not defined $layout;

    $layout .= '.tt' if $layout !~ /\.tt/;
    $layout = path(setting('views'), 'layouts', $layout);
    my $full_content =
      Dancer::Template->engine->render($layout,
        {%$tokens, content => $content});

    return $full_content;
}

use CCNQ::Portal::Outer::AccountSelection;

use constant default_content => sub {
  my $template_name = 'index';
  $template_name = 'result' if vars->{result};
  $template_name = vars->{template_name} if vars->{template_name};

  my $vars = vars;

  if(CCNQ::Portal->current_session->user) {
    $vars->{user_name} =
      CCNQ::Portal->current_session->user->profile->name;
    $vars->{is_admin} =
      CCNQ::Portal->current_session->user->profile->{is_admin} || 0;
    $vars->{is_sysadmin} =
      CCNQ::Portal->current_session->user->profile->{is_sysadmin} || 0;
  }

  my $template_params = {
    %{$vars},
    lh       => CCNQ::Portal->current_session->locale,
    accounts => CCNQ::Portal::Outer::AccountSelection->available_accounts,
    account  => CCNQ::Portal::Outer::AccountSelection->account,
  };


  my $r = ccnq_template( $template_name => $template_params );
  return ref($r) ? $r : encode_utf8($r);
};

'CCNQ::Portal::Render';