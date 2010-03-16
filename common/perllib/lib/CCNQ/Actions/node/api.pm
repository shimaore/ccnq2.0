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

=pod

  Example valid query:
    GET 'http://127.0.0.1:9090/api/node_status/api?node_name=couchdb1'
  Note how "couchdb1" is a short name; the domain name is automatically
  appended in submit_activity() (after the request went through the
  request manager).

=cut

use JSON;
use AnyEvent;
use AnyEvent::CouchDB;
use CCNQ::HTTPD;
use JSON;
use Logger::Syslog;

use CCNQ::AE;
use CCNQ::XMPPAgent;

sub _build_response_handler {
  my ($req) = @_;

  return sub {
    my ($params,$context) = @_;
    debug("node/request: Callback in process");
    if($params->{error}) {
      my $json_content = encode_json($params->{error});
      debug("node/request: Request failed: ".$json_content);
      $req->respond([500,'Request failed',{ 'Content-Type' => 'text/json' },$json_content]);
    } else {
      if($params->{result}) {
        my $json_content = encode_json($params->{result});
        debug("node/request: Request queued: $params->{status} with $json_content");
        $req->respond([200,'OK, '.$params->{status},{ 'Content-Type' => 'text/json' },$json_content]);
      } else {
        debug("node/request: Request queued: $params->{status}");
        $req->respond([200,'OK, '.$params->{status}]);
      }
    }
  };
}

sub _request {
  my ($request,$context,$mcv) = @_;
  # Silently ignore. (These come to us because we are subscribed to the manager MUC.)
  $mcv->send(CCNQ::AE::CANCEL);
}

sub _session_ready {
  my ($params,$context,$mcv) = @_;

  my $manager_muc_room = CCNQ::Install::manager_cluster_jid;
  CCNQ::XMPPAgent::_join_room($context,$manager_muc_room);

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

      debug("node/api: Contacting $manager_muc_room");
      my $r = CCNQ::XMPPAgent::send_muc_message($context,$manager_muc_room,$body);
      if($r->[0] ne 'ok') {
        $req->respond([500,$r->[1]]);
      } else {
        # Callback is used inside the _response handler.
        $context->{api_callback}->{$body->{activity}} = _build_response_handler($req);
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

      debug("node/api: Contacting $manager_muc_room");
      my $r = CCNQ::XMPPAgent::send_muc_message($context,$manager_muc_room,$body);
      if($r->[0] ne 'ok') {
        $req->respond([500,$r->[1]]);
      } else {
        # Callback is used inside the _response handler.
        $context->{api_callback}->{$body->{activity}} = _build_response_handler($req);
      }
      $httpd->stop_request;
    },

    '/provisioning' => sub {
      my ($httpd, $req) = @_;

      debug("node/provisioning: Processing web request");
      my $body = {
        activity => 'node/provisioning/'.rand(),
        action => 'retrieve',
        params => {
          $req->vars
        },
      };

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      if($path =~ m{^/provisioning/(\w+)/(\w+)/(.*)$}) {
        $body->{params}->{view} = $1.'/'.$2;
        $body->{params}->{_id}  = [split(qr|/|,$3)];
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

      debug("node/api: Contacting $manager_muc_room");
      my $r = CCNQ::XMPPAgent::send_muc_message($context,$manager_muc_room,$body);
      if($r->[0] ne 'ok') {
        $req->respond([500,$r->[1]]);
      } else {
        # Callback is used inside the _response handler.
        $context->{api_callback}->{$body->{activity}} = _build_response_handler($req);
      }
      $httpd->stop_request;
    },

  );
  $mcv->send(CCNQ::AE::SUCCESS);
}

sub _response {
  my ($response,$context,$mcv) = @_;
  my $activity = $response->{activity};
  if($activity) {
    my $cb = $context->{api_callback}->{$activity};
    if($cb) {
      debug("node/api: Using callback for activity $activity");
      $cb->($response,$context);
    } else {
      debug("node/api: Activity $activity has no registered callback");
    }
    delete $context->{api_callback}->{$activity};
  } else {
    debug("node/api: Response contains no activity ID, ignoring");
  }
  $mcv->send(CCNQ::AE::CANCEL);
}

'CCNQ::Actions::node::api';
