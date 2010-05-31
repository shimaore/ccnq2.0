package CCNQ::Portal::Outer::Theme;
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
  content_of(path(CCNQ::CCN,'themes','css',vars->{theme},'jquery-ui.css'));
};

get '/themes/css/:theme/jquery-ui.css' => sub {
  content_type 'text/css';
  content_of(path(CCNQ::CCN,'themes','css',vars->{theme},'jquery-ui.css'));
};

get r('/themes/css/([\w-]+)/images/([\w-]+)\.png') => sub {
  content_type 'image/png';
  content_of(path(CCNQ::CCN,'themes','css',(splat)[0],'images',(splat)[1].".png"));
};

=head2 Workaround for "public" documents

Dancer does not support using "prefix" for public documents.
We catch those by using /ccnq2 as a prefix.

=cut

use CCNQ::Portal;

get r('/css/([\w.-]+)\.css') => sub {
  content_type 'text/css';
  content_of(path(CCNQ::Portal::SRC,'public','ccnq2','css',(splat)[0].".css"));
};

get r('/js/([\w.-]+)\.js') => sub {
  content_type 'text/javascript';
  content_of(path(CCNQ::Portal::SRC,'public','ccnq2','js',(splat)[0].".js"));
};

get r('/js/localization/([\w.-]+)\.js') => sub {
  content_type 'text/javascript';
  content_of(path(CCNQ::Portal::SRC,'public','ccnq2','js','localization',(splat)[0].".js"));
};

get r('/images/tango-icon-theme/22x22/status/([\w-]+)\.png') => sub {
  content_type 'image/png';
  content_of(path(CCNQ::Portal::SRC,'public','ccnq2','images','tango-icon-theme','22x22','status',(splat)[0].".png"));
};

1;
