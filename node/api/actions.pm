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

=pod

  Example valid query:
    GET http://127.0.0.1:9090/request?node_name=couchdb1&action=node_status
  Note how "couchdb1" is a short name; the domain name is automatically
  appended in submit_activity() (after the request went through the
  request manager).

=cut

{
  _request => sub {
    # Silently ignore. (These come to us because we are subscribed to the manager MUC.)
    return;
  },

  _session_ready => sub {
    use JSON;
    use AnyEvent;
    use CCNQ::HTTPD;

    use CCNQ::XMPPAgent;

    my ($params,$context) = @_;

    my $muc_room = CCNQ::Install::manager_cluster_jid;
    $context->{muc}->join_room($context->{connection},$muc_room,$context->{function}.','.rand(),{
      history => {seconds=>0},
      create_instant => 1,
    });

    my $host = CCNQ::Install::api_rendezvous_host;
    my $port = CCNQ::Install::api_rendezvous_port;
    info("node/api: Starting web API on ${host}:${port}");
    $context->{httpd} = CCNQ::HTTPD->new (
      host => $host,
      port => $port,
    );

    $context->{httpd}->reg_cb(
      '' => sub {
        my ($httpd, $req) = @_;
        debug("node/api: Junking web request (no path)");
        $req->respond([404,'Not found']);
        $httpd->stop_request;
      },

      '/request' => sub {
        my ($httpd, $req) = @_;

        debug("node/api: Processing web request");
        my $body = {
          activity => 'node/api/'.rand(),
          action => '_request',
          $req->vars
        };

        if(!defined($body->{action}) || $body->{action} !~ /^\w+$/) {
          $req->respond([404,'Invalid action']);
          $httpd->stop_request;
          return;
        }

        if($req->method eq 'GET') {
          $body->{action} .= '_query';
        } elsif ($req->method eq 'PUT') {
          $body->{action} .= '_update';
        } elsif ($req->method eq 'DELETE') {
          $body->{action} .= '_delete';
        } else {
          $req->respond([501,'Invalid method']);
          $httpd->stop_request;
          return;
        }

        debug("node/api: Contacting $muc_room");
        my $r = CCNQ::XMPPAgent::send_muc_message($context,$muc_room,$body);
        if($r->[0] eq 'ok') {
          $req->respond([200,'OK']);
        } else {
          $req->respond([500,$r->[1]]);
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