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
use URI;
use JSON;
use Logger::Syslog;

sub _api_cb {
  my ($cb) = @_;
  return sub {
    my ($body, $hdr) = @_;
    if($hdr->{Status} =~ /^2/) {
      my $json = eval { decode_json($body) };
      if($@) {
        error("decode_json: $@");
        $cb->();
      } else {
        $cb->($json);
      }
    } else {
      $cb->();
    }
  };
}

sub _api {
  my ($method,$params,$cb) = @_;
  my $uri = api_uri();
  $uri->path_segments('api',delete($params->{action}),delete($params->{cluster_name}));
  $uri->query_form($params);
  http_request $method => $uri->as_string, _api_cb($cb);
}

=head1 api_query(\%params,\&cb)

=cut

sub api_query  { _api('GET',@_) }
sub api_update { _api('PUT',@_) }
sub api_delete { _api('DELETE',@_) }

sub request_query {
  my ($request_id,$cb) = @_;
  my $uri = api_uri();
  $uri->path_segments('request',$request_id);
  http_request GET => $uri->as_string, _api_cb($cb);
}

sub provisioning_query {
  my $cb = pop;
  my ($view,@id) = @_;
  my $uri = api_uri();
  $uri->path_segments('provisioning',$view,@id);
  http_request GET => $uri->as_string, _api_cb($cb);  
}

'CCNQ::API';