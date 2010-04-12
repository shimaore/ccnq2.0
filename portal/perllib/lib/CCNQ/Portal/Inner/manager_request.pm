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

=head1 /request/:request

Display the request.

=cut

use MIME::Base64;

get '/manager' => sub {
  return unless CCNQ::Portal->current_session->user;
  var template_name => 'manager_request_list';

  my $cv = AE::cv;
  CCNQ::API::manager_query(undef,$cv);
  my $res = $cv->recv;

  var result => $res;
  return CCNQ::Portal->site->default_content->();
};

post '/manager' => sub {
  return unless CCNQ::Portal->current_session->user;
  var template_name => 'manager_request';
  return CCNQ::Portal->site->default_content->();
};

get '/manager/:request_type' => sub {
  return unless CCNQ::Portal->current_session->user;
  var template_name => 'manager_request';
  my $request_type = params->{request_type};

  my $cv = AE::cv;
  CCNQ::API::manager_query($request_type,$cv);
  my $res = $cv->recv;

  var result => $res;
  return CCNQ::Portal->site->default_content->();
};

post '/manager/:request_type' => sub {
  return unless CCNQ::Portal->current_session->user;
  var template_name => 'manager_request';
  my $request_type = params->{request_type};

  my $cv = AE::cv;
  CCNQ::API::manager_update($request_type,params->{code},$cv);
  my $res = $cv->recv;

  var result => $res;
  return CCNQ::Portal->site->default_content->();
};

'CCNQ::Portal::Inner::request';
