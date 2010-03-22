package CCNQ::Actions::node::api;
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

=head1 realtime_billing

Provides a REST API to estimate_cbef().

Example valid query:
  GET 'http://127.0.0.1:7070/estimate/{account}/{account_sub}/{event_type}/{from_e164}/{to_e164}'

=cut

use JSON;
use AnyEvent;
use CCNQ::HTTPD;
use JSON;
use Logger::Syslog;

sub _session_ready {
  my ($params,$context) = @_;

  my $host = CCNQ::Install::realtime_billing_rendezvous_host;
  my $port = CCNQ::Install::realtime_billing_rendezvous_port;
  info("realtime_billing: Starting web API on ${host}:${port}");
  $context->{httpd} = CCNQ::HTTPD->new (
    host => $host,
    port => $port,
  );

  $context->{httpd}->reg_cb(
    '/estimate' => sub {
      my ($httpd, $req) = @_;

      debug("realtime_billing: Processing estimate");

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      if($path =~ m{^/estimate/(\w+)/(\w+)/(\w+)/(\d+)/(\d+)$}) {
        my $cbef = {
          account => $1,
          account_sub => $2,
          event_type => $3,
          from_e164 =>$4,
          to_e164 => $5,
        };
      } else {
        $req->respond([404,'Invalid request']);
        $httpd->stop_request;
        return;
      }

      if($req->method eq 'GET') {
        my $response = estimate_cbef($cbef);
        my $json_content = encode_json($response);
        $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);
      } else {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }

      $httpd->stop_request;
    },

  );
  return;
}

'CCNQ::Actions::realtime_billing';
