package CCNQ::Portal::Outer::UserAuthentication;
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
use CCNQ::Portal;
use CCNQ::Portal::I18N;

use CCNQ::Portal::Outer::Widget qw(if_ok);

post '/login' => sub {
  if_ok(
    CCNQ::Portal->site->security->authenticate(scalar(params),CCNQ::Portal->current_session),
    sub {
      CCNQ::Portal->current_session->start_userid(shift);
    });
    return CCNQ::Portal::content;
};

get '/logout' => sub {
  CCNQ::Portal->current_session->end();
  return CCNQ::Portal::content;
};

'CCNQ::Portal::Outer::UserAuthentication';
