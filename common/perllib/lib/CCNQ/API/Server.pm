package CCNQ::API::Server;
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
use Encode;
use URI;
use URI::Escape;
use Logger::Syslog;
use Carp;
use CCNQ::Install;
use CCNQ::Manager;
use CCNQ::API;

use CCNQ::XMPPAgent;

=head1 Tools

=head2 __generic(\&code)

Process parameters, then calls
  $code->($httpd,$req,$path,$content)
expecting either a hashref return (which is then sent over the manager MUC channel),
404 or 501, or undef.

=cut

sub __generic {
  my ($code) = @_;

  # This sub is the one called inside handle_return.
  return sub {
    my ($context, $httpd, $req) = @_;

    debug(join(', ',
      'node/api',
      'method=' => $req->method,
      'URL='    => CCNQ::AE::pp($req->url),
      'vars='   => CCNQ::AE::pp($req->vars),
      'headers='=> CCNQ::AE::pp($req->headers),
      'body='   => CCNQ::AE::pp($req->content),
    ));

    # Accept a JSON body as parameters as well.
    my $content = {};
    if($req->content) {
      my $json = eval { decode_json($req->content) };
      if($@) {
        debug('Invalid JSON content');
        $req->respond([501,'Invalid JSON content']);
        $httpd->stop_request;
        return;
      }
      if(ref($json) ne 'HASH') {
        debug('JSON content is not a hash');
        $req->respond([501,'JSON content is not a hash']);
        $httpd->stop_request;
        return;
      }
      $content = $json;
    }

    # Gather the path
    use URI;
    my $url = URI->new($req->url);
    my $path = $url->path;

    # Call the callback
    my $body = $code->($httpd,$req,$path,$content);

    # If a hashref is returned it is used as the body for a manager request.
    if(ref($body)) {
      my $manager_muc_room = CCNQ::Manager::manager_cluster_jid;
      debug("node/api: Contacting $manager_muc_room");
      my $activity;
      my $r = CCNQ::XMPPAgent::send_muc_message($context,$manager_muc_room,$body);
      if($r->[0] ne 'ok') {
        $req->respond([500,$r->[1]]);
      } else {
        $activity = $body->{activity};
      }
      $httpd->stop_request;
      # Pass the activity ID back to handle_return() so that a callback is created for it.
      return $activity;
    }

    # Otherwise an integer (404 or 501) might be returned to indicate an error.
    if(defined($body)) {
      if($body == 404) {
        $req->respond([404,'Invalid request']);
        $httpd->stop_request;
        return;
      }
      if($body == 501) {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }
    }

    $httpd->stop_request;
    return;
  };
}

=head2 __view_cb($req)

Returns a sub that can be used as a callback for a CCNQ::CouchDB view.

=cut

sub __view_cb {
  my ($req) = @_;
  return sub {
    my $response = CCNQ::AE::receive(shift);
    if($response) {
      $req->respond([200,'OK',{ 'Content-Type' => 'text/json' }, encode_json($response)]);
    } else {
      $req->respond([500,'No results']);
    }
  };
};

sub __build_response_handler {
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

=head1 API modules

=head2 _api_default

Returns a 404 error for non-defined URLs.

=cut

use constant _api_default => __generic(sub {
  return 404;
});

=head2 _api

Handles /api calls.

=cut

use constant _api => __generic(sub {
  my ($httpd, $req, $path, $content) = @_;

  my $suffix = {
    GET     => '_query',
    PUT     => '_update',
    DELETE  => '_delete',
  }->{$req->method};

  $suffix or return 501;

  debug("node/api: Processing api request");
  my $body = {
    activity => 'node/api/'.rand(),
    action => 'new_request', # ran by the 'manager'
    params => {
      $req->vars,
      %$content
    },
  };

  if($path =~ m{^/api/(\w+)/([\w-]+)$}) {
    $body->{params}->{type} = $1;   # request type
    $body->{params}->{action} = $1; # actual request action (completed below)
    $body->{params}->{cluster_name} = $2;
  } elsif($path =~ m{^/api/(\w+)$}) {
    $body->{params}->{type} = $1;   # request type
    $body->{params}->{action} = $1; # actual request action (completed below)
  } else {
    return 404;
  }

  $body->{params}->{action} .= $suffix;

  return $body;
});

=head2 _request

Handles /request calls.

=cut

use constant _request => __generic(sub {
  my ($httpd, $req, $path) = @_;

  $req->method eq 'GET' or return 501;

  my $body = {
    activity => 'node/request/'.rand(),
    action => 'get_request_status',
  };

  if($path =~ m{^/request/(\w+)$}) {
    $body->{request_id} = $1;
  } else {
    return 404;
  }

  return $body;
});

=head2 _provisioning

Handles /provisioning calls.

=cut

use constant _provisioning => __generic(sub {
  my ($httpd, $req, $path) = @_;

  $req->method eq 'GET' or return 501;

  my ($view,$id);
  if($path =~ m{^/provisioning/(\w+)/(\w+)/(.*)$}) {
    $view = $1.'/'.$2;
    $id   = [map { decode_utf8(uri_unescape($_)) } split(qr|/|,$3)];
  } else {
    return 404;
  }

  CCNQ::Provisioning::provisioning_view({
    view => $view,
    _id  => $id,
  })->cb(__view_cb($req));

  $httpd->stop_request;
  return;
});

=head2 _billing

Handles /billing calls

=cut

use constant _billing => __generic(sub {
  my ($httpd, $req, $path) = @_;

  $req->method eq 'GET' or return 501;

  my ($view,$id);
  if($path =~ m{^/billing/(\w+)/(\w+)/(.*)$}) {
    $view = $1.'/'.$2;
    $id   = [map { decode_utf8(uri_unescape($_)) } split(qr|/|,$3)];
  }
  # This is valid e.g. to enumerate the buckets metadata.
  elsif($path =~ m{^/billing/(\w+)/(\w+)$}) {
    $view = $1.'/'.$2;
    $id = [];
  } else {
    return 404;
  }

  CCNQ::Billing::billing_view({
    view => $view,
    _id  => $id,
  })->cb(__view_cb($req));

  $httpd->stop_request;
  return;
});

=head2 _rating_table

Handles /rating_table calls.

=cut

use constant _rating_table => __generic(sub {
  my ($httpd, $req, $path) = @_;

  $req->method eq 'GET' or return 501;

  my ($table,$prefix);
  if($path =~ m{^/rating_table/(\w+)/(\S+)$}) {
    ($table,$prefix) = ($1,$2);
  } elsif($path =~ m{^/rating_table/(\w+)$}) {
    ($table) = ($1);
  } elsif($path =~ m{^/rating_table$}) {
    # List all tables
  } else {
    return 404;
  }

  my $cv;
  if(defined $table) {
    if(defined $prefix) {
      $cv = CCNQ::Billing::Table::retrieve_prefix({ name => $table, prefix => $prefix });
    } else {
      $cv = CCNQ::Billing::Table::all_prefixes({ name => $table });
    }
  } else {
    $cv = CCNQ::Billing::Table::all_tables();
  }

  $cv or return 501;

  $cv->cb(__view_cb($req));

  $httpd->stop_request;
  return;
});

=head2 _bucket

Handles /bucket calls.

=cut

use constant _bucket => __generic(sub {
  my ($httpd, $req, $path, $content) = @_;

  my $params = {
    $req->vars,
    %$content
  };

  my $cv;
  # Account or account-sub level (Bucket instance) data
  if($path =~ m{^/bucket$}) {
    use CCNQ::Rating::Bucket;
    my $bucket = CCNQ::Rating::Bucket->new($params->{name},$params->{use_account});
    # GET: name account (account_sub)
    $cv = $bucket->get_instance($params)  if $req->method eq 'GET';
    # PUT: name account (account_sub) value currency
    $cv = $bucket->replenish($params)     if $req->method eq 'PUT';
  } else {
    return 404;
  }

  $cv or return 501;

  $cv->cb(__view_cb($req));

  $httpd->stop_request;
  return;
});

=head2 _manager

Handles /manager calls.

=cut

use constant _manager => __generic(sub {
  my ($httpd, $req, $path, $content) = @_;

  debug("node/api: Processing manager mapping request");
  my $body = {
    activity => 'manager/'.rand(),
  };

  if($path =~ m{^/manager/([\w-]+)$}) {
    # Retrieve / update / delete one
    $body->{_id} = $1;   # request type
    delete $body->{action};
    if($req->method eq 'GET') {
      $body->{action} = 'manager_retrieve';
    } elsif ($req->method eq 'PUT') {
      $body->{action} = 'manager_update';
      $body->{code} = $content->{code};
    } elsif ($req->method eq 'DELETE') {
      $body->{action} = 'manager_delete';
    }
  } elsif($path =~ m{^/manager$}) {
    # List all
    $body->{view}   = '_all_docs';
    delete $body->{action};
    if($req->method eq 'GET') {
      $body->{action} = 'manager_view';
    }
  } else {
    return 404;
  }

  $body->{action} or return 501;

  return $body;
});

=head1 Actions

=head2 _session_ready

=cut

sub _session_ready {
  my ($params,$context) = @_;

  my $manager_muc_room = CCNQ::Manager::manager_cluster_jid;
  CCNQ::XMPPAgent::_join_room($context,$manager_muc_room);

  my $host = CCNQ::API::api_rendezvous_host;
  my $port = CCNQ::API::api_rendezvous_port;
  info("node/api: Starting web API on ${host}:${port}");
  $context->{httpd} = CCNQ::HTTPD->new (
    host => $host,
    port => $port,
  );

  my $handle_return = sub {
    my ($code,$httpd,$req) = @_;
    my $r = eval { $code->($context,$httpd,$req) };
    $@ and debug("code failed: $@");
    $context->{api_callback}->{$r} = __build_response_handler($req) if defined $r;
  };

  $context->{httpd}->reg_cb(
    ''              => sub { $handle_return->(_api_default,@_) },
    '/api'          => sub { $handle_return->(_api,@_) },
    '/request'      => sub { $handle_return->(_request,@_) },
    '/provisioning' => sub { $handle_return->(_provisioning,@_) },
    '/billing'      => sub { $handle_return->(_billing,@_) },
    '/rating_table' => sub { $handle_return->(_rating_table,@_) },
    '/bucket'       => sub { $handle_return->(_bucket,@_) },
    '/manager'      => sub { $handle_return->(_manager,@_) },
  );
  return;
}

=head2 _response

=cut

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

'CCNQ::API::Server';
