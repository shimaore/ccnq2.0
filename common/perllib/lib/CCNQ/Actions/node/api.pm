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
use CCNQ::AE;
use CCNQ::HTTPD;
use JSON;
use Logger::Syslog;
use Carp;
use CCNQ::Install;
use CCNQ::API;

use CCNQ::XMPPAgent;

sub _build_response_handler {
  my ($req) = @_;

  return sub {
    my ($response,$context) = @_;
    debug("node/api: Callback in process");
    if($response->{error}) {
      # Note: error must be an arrayref.
      error("node/api: {error} must be an ARRAY")
        unless ref($response->{error}) eq 'ARRAY';
      my $json_content = encode_json($response->{error});
      debug("node/api: Request failed: ".$json_content);
      $req->respond([500,'Request submission failed',{ 'Content-Type' => 'text/json' },$json_content]);
    } else {
      # Since "status" is not the marker used to decide whether there was an error,
      # it should always be 'completed' if no {error} is present.
      error(Carp::longmess("node/api: Coding error: status is '$response->{status}', but no {error} present, should be 'completed'"))
        if $response->{status} ne 'completed';
      if($response->{result}) {
        my $json_content = encode_json($response->{result});
        debug("node/api: Request queued: $response->{status} with $json_content");
        $req->respond([200,'OK, '.$response->{status},{ 'Content-Type' => 'text/json' },$json_content]);
      } else {
        debug("node/api: Request queued: $response->{status}");
        $req->respond([200,'OK, '.$response->{status}]);
      }
    }
  };
}

sub _request {
  my ($request,$context) = @_;
  # Silently ignore. (These come to us because we are subscribed to the manager MUC.)
  return;
}

sub _session_ready {
  my ($params,$context) = @_;

  my $manager_muc_room = CCNQ::Install::manager_cluster_jid;
  CCNQ::XMPPAgent::_join_room($context,$manager_muc_room);

  my $host = CCNQ::API::api_rendezvous_host;
  my $port = CCNQ::API::api_rendezvous_port;
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

      debug("node/api: Processing web new_request");
      my $body = {
        activity => 'node/api/'.rand(),
        action => 'new_request', # ran by the 'manager'
        params => {
          $req->vars
        },
      };

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      if($path =~ m{^/api/(\w+)/([\w-]+)$}) {
        $body->{params}->{type} = $1;   # request type
        $body->{params}->{action} = $1; # actual request action (completed below)
        $body->{params}->{cluster_name} = $2;
      } elsif($path =~ m{^/api/(\w+)$}) {
        $body->{params}->{type} = $1;   # request type
        $body->{params}->{action} = $1; # actual request action (completed below)
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

      debug("node/api: Processing web get_request_status");
      my $body = {
        activity => 'node/request/'.rand(),
        action => 'get_request_status',
      };

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      if($path =~ m{^/request/(\w+)$}) {
        $body->{request_id} = $1;
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

    # For provisioning we use our local copy of the database.
    '/provisioning' => sub {
      my ($httpd, $req) = @_;

      debug("node/api: Processing provisioning view");

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      my ($view,$id);
      if($path =~ m{^/provisioning/(\w+)/(\w+)/(.*)$}) {
        $view = $1.'/'.$2;
        $id   = [split(qr|/|,$3)];
      } else {
        $req->respond([404,'Invalid request']);
        $httpd->stop_request;
        return;
      }

      if($req->method ne 'GET') {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }

      CCNQ::Provisioning::provisioning_view({
        view => $view,
        _id  => $id,
      })->cb(sub{
        my $response = CCNQ::AE::receive(shift);
        if($response) {
          $req->respond([200,'OK',{ 'Content-Type' => 'text/json' }, encode_json($response)]);
        } else {
          $req->respond([500,'No results']);
        }
      });

      $httpd->stop_request;
    },

    # For billing we use our local copy of the database.
    '/billing' => sub {
      my ($httpd, $req) = @_;

      debug("node/api: Processing billing view");

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      my ($view,$id);
      if($path =~ m{^/billing/(\w+)/(\w+)/(.*)$}) {
        $view = $1.'/'.$2;
        $id   = [split(qr|/|,$3)];
      } else {
        $req->respond([404,'Invalid request']);
        $httpd->stop_request;
        return;
      }

      if($req->method ne 'GET') {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }

      CCNQ::Billing::billing_view({
        view => $view,
        _id  => $id,
      })->cb(sub{
        my $response = CCNQ::AE::receive(shift);
        if($response) {
          $req->respond([200,'OK',{ 'Content-Type' => 'text/json' }, encode_json($response)]);
        } else {
          $req->respond([500,'No results']);
        }
      });

      $httpd->stop_request;
    },

    '/manager' => sub {
      my ($httpd, $req) = @_;

      debug("node/api: Processing manager mapping request");
      my $body = {
        activity => 'manager/'.rand(),
      };

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      if($path =~ m{^/manager/([\w-]+)$}) {
        # Retrieve / update / delete one
        $body->{_id} = $1;   # request type
        if($req->method eq 'GET') {
          $body->{action} = 'manager_retrieve';
        } elsif ($req->method eq 'PUT') {
          $body->{action} = 'manager_update';
          $body->{code} = $req->parm('code');
        } elsif ($req->method eq 'DELETE') {
          $body->{action} = 'manager_delete';
        }
      } elsif($path =~ m{^/manager$}) {
        # List all
        $body->{_id}    = [];
        $body->{view}   = '_all_docs';
        delete $body->{action};
        if($req->method eq 'GET') {
          $body->{action} = 'manager_view';
        }
      } else {
        $req->respond([404,'Invalid request']);
        $httpd->stop_request;
        return;
      }

      if(! defined($body->{action})) {
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
  return;
}

sub _response {
  my ($response,$context) = @_;
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
  return;
}

'CCNQ::Actions::node::api';
