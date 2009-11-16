# node/api/actions.pm

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
    my ($request,$context,$mcv) = @_;
    # Silently ignore. (These come to us because we are subscribed to the manager MUC.)
    $mcv->send(CCNQ::Install::CANCEL);
  },

  _session_ready => sub {
    my ($params,$context,$mcv) = @_;

    use JSON;
    use AnyEvent;
    use CCNQ::HTTPD;
    use JSON;

    use CCNQ::XMPPAgent;

    my $muc_room = CCNQ::Install::manager_cluster_jid;
    CCNQ::XMPPAgent::_join_room($context,$muc_room);

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
          params => {
            $req->vars
          },
        };

        if(!defined($body->{params}->{action}) || $body->{params}->{action} !~ /^\w+$/) {
          $req->respond([404,'Invalid action']);
          $httpd->stop_request;
          return;
        }

        if($req->method eq 'GET') {
          $body->{params}->{action} .= '_query';
        } elsif ($req->method eq 'PUT') {
          $body->{params}->{action} .= '_update';
        } elsif ($req->method eq 'DELETE') {
          $body->{params}->{action} .= '_delete';
        } else {
          $req->respond([501,'Invalid method']);
          $httpd->stop_request;
          return;
        }

        debug("node/api: Contacting $muc_room");
        my $r = CCNQ::XMPPAgent::send_muc_message($context,$muc_room,$body);
        if($r->[0] ne 'ok') {
          $req->respond([500,$r->[1]]);
        } else {
          # Callback is used inside the _response handler.
          $context->{api_callback}->{$body->{activity}} = sub {
            my ($params,$context) = @_;
            debug("node/api: Callback in process");
            if($params->{error}) {
              debug("node/api: Request failed: ".$params->{error});
              $req->respond([500,'Request failed',{ 'Content-Type' => 'text/plain' },$params->{error}]);
            } else {
              if($params->{params}) {
                my $json_content = encode_json($params->{params});
                debug("node/api: Request queued: $params->{status} with $json_content");
                $req->respond([201,'Request queued: '.$params->{status},{ 'Content-Type' => 'text/json' },$json_content]);
              } else {
                debug("node/api: Request queued: $params->{status}");
                $req->respond([201,'Request queued: '.$params->{status}]);
              }
            }
          };
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
    $mcv->send(CCNQ::Install::SUCCESS);
  },

  _response => sub {
    my ($params,$context,$mcv) = @_;
    my $activity = $params->{activity};
    if($activity) {
      my $cb = $context->{api_callback}->{$activity};
      if($cb) {
        debug("node/api: Using callback for activity $activity");
        $cb->($params,$context);
      } else {
        debug("node/api: Activity $activity has no registered callback");
      }
    } else {
      debug("node/api: Response contains no activity ID, ignoring");
    }
    $mcv->send(CCNQ::Install::CANCEL);
  },

}