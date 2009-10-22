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

{
  _session_ready => sub {
    use JSON;
    use AnyEvent;
    use AnyEvent::HTTPD;

    our ($context) = @_;

    our $muc_room = CCNQ::Install::manager_cluster_name;
    # This should have been done by 'node':
    $context->{muc}->join_room($context->{connection},$muc_room);

    my $host = CCNQ::Install::api_rendezvous_host;
    my $port = CCNQ::Install::api_rendezvous_port;
    info("node/api: Starting web API on ${host}:${port}");
    $context->{httpd} = AnyEvent::HTTPD->new (
      host => $host,
      port => $port,
    );

    $context->{httpd}->reg_cb(
      '' => sub {
        my ($httpd, $req) = @_;
        debug("node/api: Junking web request");
        $req->respond([404,'Not found']);
        $httpd->stop_request;
      },

      '/request' => sub {
        my ($httpd, $req) = @_;

        debug("node/api: Processing web request");
        my $response = {
          activity => 'node/api',
          action => 'request',
          params => $req->vars,
        };

        CCNQ::XMPPAgent::authenticate_response($response,$muc_room);

        my $room = $context->{muc}->get_room ($context->{connection}, $muc_room);
        if($room) {
          debug("node/api: Forwarding request");
          my $msg = encode_json($response);
          my $immsg = $room->make_message(body => $msg);
          $immsg->send();
          $req->respond([200,'OK']);
        } else {
          debug("node/api: Not joined yet");
          $req->respond([500,'Not joined yet']);
        }
        $httpd->stop_request;
      },
      '/node' => sub {
        my ($httpd, $req) = @_;
        debug("node/api: Junking web request");
        $req->respond([404,'Not found']);
        $httpd->stop_request;
      },
    );
    return { ok => 1 };
  },

}