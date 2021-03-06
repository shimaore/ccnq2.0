package CCNQ::Portal::Outer::Theme;
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
use CCNQ;
use CCNQ::Util;

our %cache;
sub content_of {
  my $path = shift;
  return $cache{$path} ||= CCNQ::Util::content_of($path);
}

=head2 Theming

It is up to the local package to provide a proper jquery-ui installation
(such as provided by themeroller) in /etc/ccn/themes.

=cut

get '/themes/js/jquery.js' => sub {
  content_type 'text/javascript';
  content_of(path(CCNQ::CCN,'themes','js','jquery.js'));
};

get '/themes/js/jquery-ui.js' => sub {
  content_type 'text/javascript';
  content_of(path(CCNQ::CCN,'themes','js','jquery-ui.js'));
};

get '/themes/css/:theme/jquery-ui.css' => sub {
  content_type 'text/css';
  content_of(path(CCNQ::CCN,'themes','css',params->{theme},'jquery-ui.css'));
};

get '/themes/css/:theme/jquery-ui.css' => sub {
  content_type 'text/css';
  content_of(path(CCNQ::CCN,'themes','css',params->{theme},'jquery-ui.css'));
};

get '/themes/css/:theme/style.css' => sub {
  content_type 'text/css';
  content_of(path(CCNQ::CCN,'themes','css',params->{theme},'style.css'));
};

get qr{/themes/css/([\w-]+)/images/([\w-]+)\.png} => sub {
  content_type 'image/png';
  content_of(path(CCNQ::CCN,'themes','css',(splat)[0],'images',(splat)[1].".png"));
};

=head2 Workaround for "public" documents

Dancer does not support using "prefix" for public documents.
We catch those by using /ccnq2 as a prefix.

=cut

use CCNQ::Portal;

get qr{/css/([\w.-]+)\.css} => sub {
  content_type 'text/css';
  content_of(path(CCNQ::Portal::SRC,'public','css',(splat)[0].".css"));
};

get qr{/js/([\w.-]+)\.js} => sub {
  content_type 'text/javascript';
  content_of(path(CCNQ::Portal::SRC,'public','js',(splat)[0].".js"));
};

get qr{/images/([\w.-]+)\.gif} => sub {
  content_type 'text/javascript';
  content_of(path(CCNQ::Portal::SRC,'public','js',(splat)[0].".gif"));
};

get qr{/js/localization/([\w.-]+)\.js} => sub {
  content_type 'text/javascript';
  content_of(path(CCNQ::Portal::SRC,'public','js','localization',(splat)[0].".js"));
};

1;
