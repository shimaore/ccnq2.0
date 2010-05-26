package CCNQ::Portal::Inner::Trace;
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
use CCNQ::Portal::Util;

use CCNQ::AE;
use CCNQ::API;

use constant TRACE_SERVERS_DNS_NAME => 'trace-server';

use CCNQ::Install;

sub get_node_names {
  my $dns_txt = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::txt( $dn, $cv );
    return ($cv->recv);
  };

  return [sort $dns_txt->(CCNQ::Install::cluster_fqdn(TRACE_SERVERS_DNS_NAME))];
}

get '/trace' => sub {
  var template_name => 'api/trace';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_admin;

  var field => {
    node_names => get_node_names(),
  };
  return CCNQ::Portal::content;
};

post '/trace' => sub {
  var template_name => 'api/trace';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_admin;

  my $params = CCNQ::Portal::Util::neat({},qw(
    node_name
    dump_packets
    call_id
    to_user
    from_user
    days_ago
  ));

  my $cv1 = AE::cv;
  CCNQ::API::api_query('trace',$params,$cv1);
  return CCNQ::Portal::Util::redirect_request($cv1);
};

'CCNQ::Portal::Inner::Trace';
