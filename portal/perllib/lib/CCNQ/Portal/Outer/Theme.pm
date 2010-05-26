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

=head2 Theming

It is up to the local package to provide a proper jquery-ui installation
(such as provided by themeroller) in /etc/ccn/themes.

=cut

get '/themes/js/jquery.js' => sub {
  send_file(path(CCNQ::CCN,'themes','js','jquery.js'));
};

get '/themes/js/jquery-ui.js' => sub {
  send_file(path(CCNQ::CCN,'themes','js','jquery-ui.js'));
};

get '/themes/css/:theme/jquery-ui.css' => sub {
  send_file(path(CCNQ::CCN,'themes','css',vars->{theme},'jquery-ui.css'));
};

get '/themes/css/:theme/jquery-ui.css' => sub {
  send_file(path(CCNQ::CCN,'themes','css',vars->{theme},'jquery-ui.css'));
};

get '/themes/css/:theme/images/:file.css' => sub {
  send_file(path(CCNQ::CCN,'themes','css',vars->{theme},'images',vars->{file}.".css"));
};

1;
