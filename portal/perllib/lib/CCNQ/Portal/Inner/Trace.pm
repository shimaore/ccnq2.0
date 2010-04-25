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
  return unless CCNQ::Portal->current_session->user;
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  var field => {
    node_names => get_node_names(),
  };
  var template_name => 'api/trace';
  return CCNQ::Portal->site->default_content->();
};

post '/trace' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  my $cv1 = AE::cv;
  CCNQ::API::api_query('trace',params,$cv1);
  my $r = CCNQ::AE::receive($cv1);
  debug($r);

  # Redirect to the request
  redirect '/request/'.$r->{request};
};

'CCNQ::Portal::Inner::Trace';
