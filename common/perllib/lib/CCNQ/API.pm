package CCNQ::API;
# Copyright (C) 2010  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use constant api_rendezvous_host => '127.0.0.1';
use constant api_rendezvous_port => 9090;

use URI;
use Encode;

use constant::defer api_uri => sub {
  my $uri = URI->new();
  $uri->scheme('http');
  $uri->host(api_rendezvous_host);
  $uri->port(api_rendezvous_port);
  return $uri;
};

=head1 Client-side functions

These functions are used by an API client to manipulate the API.

=cut

use AnyEvent;
use CCNQ::AE;
use AnyEvent::HTTP;
use CCNQ::Install;
use JSON;
use Logger::Syslog;

sub _api_cb {
  my ($cb) = @_;
  return sub {
    my ($body, $hdr) = @_;
    if($hdr->{Status} =~ /^2/) {
      if($body) {
        my $json = eval { decode_json($body) };
        if($@) {
          error("decode_json($body): $@");
        } else {
          $cb->($json);
          return;
        }
      }
    }
    $cb->();
  };
}

sub _api {
  my ($method,$action,$params,$cb) = @_;
  my $uri = api_uri();
  $uri->path_segments('api',$action);
  my $body = undef;
  # See CCNQ::HTTPD
  if($method eq 'PUT') {
    $body = encode_json($params);
  } else {
    $uri->query_form($params);
  }
  http_request $method => $uri->as_string, body => $body, _api_cb($cb);
  return;
}

=head1 api_update($action,$params,$cb)

=head1 api_delete($action,$params,$cb)

=cut

sub api_query  { _api('GET',@_) }
sub api_update { _api('PUT',@_) }
sub api_delete { _api('DELETE',@_) }

sub request {
  my ($request_id,$cb) = @_;
  my $uri = api_uri();
  $uri->path_segments('request',$request_id);
  http_get $uri->as_string, _api_cb($cb);
  return;
}

sub _path_api {
  my $prefix = shift;
  my $cb = pop;
  my (@fields) = @_;
  my $uri = api_uri();
  $uri->path_segments($prefix,map { Encode::encode_utf8($_) } @fields);
  http_get $uri->as_string, _api_cb($cb);
  return;
}

sub cdr          { _path_api('cdr'         ,@_) }

sub _view_api {
  my $prefix = shift;
  my $cb = pop;
  my ($design,$view,@id) = @_;
  my $uri = api_uri();
  $uri->path_segments($prefix,$design,$view,map { Encode::encode_utf8($_) } @id);
  http_get $uri->as_string, _api_cb($cb);
  return;
}

sub provisioning { _view_api('provisioning',@_) }
sub billing      { _view_api('billing'     ,@_) }
sub invoicing    { _view_api('invoicing'   ,@_) }

sub _bucket {
  my $cb = pop;
  my ($method,$params) = @_;
  my $uri = api_uri();
  $uri->path_segments('bucket');
  my $body;
  # See CCNQ::HTTPD
  if($method eq 'PUT') {
    $body = encode_json($params);
  } else {
    $uri->query_form($params);
  }
  http_request $method => $uri->as_string, body => $body, _api_cb($cb);
  return;
}

sub bucket_query  { _bucket('GET',@_) }
sub bucket_update { _bucket('PUT',@_) }

sub rating_table {
  my $cb = pop;
  my $uri = api_uri();
  $uri->path_segments('rating_table',map { Encode::encode_utf8($_) } @_);
  http_get $uri->as_string, _api_cb($cb);
  return;
}

sub _manager {
  my $cb = pop;
  my ($method,$request_type,$code) = @_;
  my $uri = api_uri();
  if(defined($request_type)) {
    $uri->path_segments('manager',$request_type);
  } else {
    $uri->path_segments('manager');  # view
  }
  my $body;
  $body = encode_json({code => $code}) if $code;
  http_request $method => $uri->as_string, body => $body, _api_cb($cb);
  return;
}

sub manager_query  { _manager('GET',@_) }
sub manager_update { _manager('PUT',@_) }
sub manager_delete { _manager('DELETE',@_) }

'CCNQ::API';
