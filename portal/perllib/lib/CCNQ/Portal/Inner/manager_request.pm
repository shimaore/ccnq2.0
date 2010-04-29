package CCNQ::Portal::Inner::request;
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
use CCNQ::API;
use AnyEvent;

=head1 /request/:request

Display the request.

=cut

get '/manager' => sub {
  var template_name => 'manager_request_list';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;

  my $cv = AE::cv;
  CCNQ::API::manager_query(undef,$cv);
  my $res = $cv->recv;

  var result => $res;
  return CCNQ::Portal::content;
};

my $get_query_type = sub {
  var template_name => 'manager_request';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;

  my $request_type = params->{request_type};

  my $cv = AE::cv;
  CCNQ::API::manager_query($request_type,$cv);
  my $res = $cv->recv;

  var result => $res;
  return CCNQ::Portal::content;
};

post '/manager'              => $get_query_type;
get '/manager/:request_type' => $get_query_type;

post '/manager/:request_type' => sub {
  var template_name => 'manager_request';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_sysadmin;

  my $request_type = params->{request_type};

  my $cv = AE::cv;
  CCNQ::API::manager_update($request_type,params->{code},$cv);
  my $res = $cv->recv;

  var result => $res;
  return CCNQ::Portal::content;
};

'CCNQ::Portal::Inner::request';
