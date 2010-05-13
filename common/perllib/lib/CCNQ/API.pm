package CCNQ::API;
# Copyright (C) 2010  Stephane Alnet
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

sub request_query {
  my ($request_id,$cb) = @_;
  my $uri = api_uri();
  $uri->path_segments('request',$request_id);
  http_get $uri->as_string, _api_cb($cb);
  return;
}

sub provisioning_view {
  my $cb = pop;
  my ($design,$view,@id) = @_;
  my $uri = api_uri();
  $uri->path_segments('provisioning',$design,$view,map { Encode::encode_utf8($_) } @id);
  http_get $uri->as_string, _api_cb($cb);
  return;
}

sub escape_utf8_uri {
  my ($t) = @_;
  $t = encode_utf8($t);
  $t =~ s/([^\w])/sprintf('%%%02x',ord($1))/gxe;
  return $t;
}

sub billing_view {
  my $cb = pop;
  my ($design,$view,@id) = @_;
  my $uri = api_uri();
  my $uri_string = $uri->as_string;
  my @map_id = map {escape_utf8_uri($_)} @id;
  use CCNQ::AE; debug("billing_view: ".CCNQ::AE::pp([$design,$view,[@id],[@map_id]]));
  my $path = join('/','billing',$design,$view,@map_id);
  my $uri_final = "$uri_string/$path";
  debug("billing_view: Querying $uri_final");
  http_get $uri_final, _api_cb($cb);
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
