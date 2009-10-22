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
    use AnyEvent::HTTPD;

    our ($context) = @_;

    our $muc_room = CCNQ::Install::manager_cluster_name;
    # This should have been done by 'node':
    # $context->{muc}->join_room($context->{connection},$muc_room);

    my $httpd = AnyEvent::HTTPD->new (
      host => api_rendezvous_host,
      port => api_rendezvous_port,
    );

    $httpd->reg_cb(
      '/request' => sub {
        my ($httpd, $req) = @_;

        my $response = {
          activity => 1, # initial activity, meaning: new request
          action => 'request',
          params => $req->vars,
        };

        CCNQ::XMPPAgent::authenticate_response($response,$muc_room);

        my $room = $context->{muc}->get_room ($context->{connection}, $muc_room);
        if($room) {
          my $msg = encode_json($response);
          my $immsg = $room->make_message(body => $msg);
          $immsg->send();
          return $req->respond([200,'OK']);
        } else {
          return $req->respond([500,'Not joined yet']);
        }

      },
      '/node' => sub {

      },
    );
    $httpd->run;
    return { ok => 1 };
  },

}