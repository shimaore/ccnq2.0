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
    GET 'http://127.0.0.1:9090/api/node_status/api?node_name=couchdb1'
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
    use AnyEvent::CouchDB;
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

    use CCNQ::API::handler;

    $context->{httpd}->reg_cb(
      '' => sub {
        my ($httpd, $req) = @_;
        debug("node/api: Junking web request (no path)");
        $req->respond([404,'Not found']);
        $httpd->stop_request;
      },

      '/api' => sub {
        my ($httpd, $req) = @_;

        debug("node/api: Processing web request");
        my $body = {
          activity => 'node/api/'.rand(),
          action => '_request', # ran by the 'manager'
          params => {
            $req->vars
          },
        };

        use URI;
        my $url = URI->new($req->url);
        my $path = $url->path;

        if($path =~ m{^/api/(\w+)/([\w-]+)$}) {
          $body->{params}->{action} = $1;
          $body->{params}->{cluster_name} = $2;
        } else {
          $req->respond([404,'Invalid request']);
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

      '/request' => sub {
        my ($httpd, $req) = @_;

        debug("node/request: Processing web request");
        my $body = {
          activity => 'node/request/'.rand(),
          action => 'get_request_status',
          params => {
            $req->vars
          },
        };

        use URI;
        my $url = URI->new($req->url);
        my $path = $url->path;

        if($path =~ m{^/request/(\w+)$}) {
          $body->{params}->{request_id} = $1;
        } else {
          $req->respond([404,'Invalid request']);
          $httpd->stop_request;
          return;
        }

        if($req->method eq 'GET') {
          # OK
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
            debug("node/request: Callback in process");
            if($params->{error}) {
              debug("node/request: Request failed: ".$params->{error});
              $req->respond([500,'Request failed',{ 'Content-Type' => 'text/plain' },$params->{error}]);
            } else {
              if($params->{params}) {
                my $json_content = encode_json($params->{params});
                debug("node/request: Request queued: $params->{status} with $json_content");
                $req->respond([200,'OK, '.$params->{status},{ 'Content-Type' => 'text/json' },$json_content]);
              } else {
                debug("node/request: Request queued: $params->{status}");
                $req->respond([200,'OK, '.$params->{status}]);
              }
            }
          };
        }
        $httpd->stop_request;
      },

      '/form' => sub {
        my ($httpd, $req) = @_;

        debug("node/form: Processing web request");
        my $body = {
          activity => 'node/form/'.rand(),
          action => 'submit_form',
          params => {
            $req->vars
          },
        };

      },

      '/view' => sub {
        my ($httpd, $req) = @_;

        debug("node/view: Processing web request");
        my $body = {
          activity => 'node/view/'.rand(),
          action => 'view_form',
          params => {
            $req->vars
          },
        };

      },

      '/account' => CCNQ::API::handler::make_couchdb_proxy(
          $context,
          'by/account',                              # View name
          'account', [qw(account)],                  # Key
          [qw(name billing_address billing_cycle)],
          [qw(name billing_address billing_cycle)],
      ),

      '/account_sub' => CCNQ::API::handler::make_couchdb_proxy(
          $context,
          'by/account_sub',                          # View name
          'account_sub', [qw(account account_sub)],  # Key
          [qw(label plan)],
          [qw(label plan)],
      ),

      '/user' =>      CCNQ::API::handler::make_couchdb_proxy(
          # XXX "billing_account" method needs finer-grained processing (add/remove from a list)
          $context,
          'by/user',                                 # View name
          'user', [qw(username)],                    # Key
          [qw(email billing_accounts)],
          [qw(email billing_accounts)],
      ),
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
      delete $context->{api_callback}->{$activity};
    } else {
      debug("node/api: Response contains no activity ID, ignoring");
    }
    $mcv->send(CCNQ::Install::CANCEL);
  },

}
