package CCNQ::Actions::realtime_estimator;
# Copyright (C) 2009  Stephane Alnet
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

=head1 realtime_estimator

Provides a REST API to estimate_cbef().

=head2 "estimate" query

  GET 'http://127.0.0.1:7070/estimate/{account}/{account_sub}/{event_type}/{from_e164}/{to_e164}'

    event_type:         (e.g.) "egress_call" (most common)

=head2 "update" query

  GET 'http://127.0.0.1:7070/update/{account}/{account_sub}/{event_type}/{from_e164}/{to_e164}/{call_uuid}/{request_sequence}/{duration_since_last_request}'

    call_uuid:          some UUID for the call
    request_sequence:   a value that starts at 1 and is incremented for each such request
          the combination call_uuid + request_sequence allows the server to
          uniquely identify the request and prevents duplicate submissions
    duration_since_last_request:
                        the number of seconds (in call time) since the previous request
    start_date
    start_time

=head2 Sequence of calls

Typically, a script will send an "estimate" request at the beginning of the call,
and an "update" request every N seconds during the call. The "update" requests
are uniquely identified by the call_uuid and the request_sequence number which
will take the value 1 at the first N seconds of the call, the value 2 when the call
duration is 2*N seconds, etc. However the "duration_since_last request" will remain
approximatively the same, at around N seconds, except for the last "update" message, which
is sent after the call was hung up to provide the duration of the last segment of the call.

For example, for N=60, and a call that lasts 138 seconds, the messages may be:
  GET .../estimate/...
  GET .../update/.../1/60
  GET .../update/.../2/60
  GET .../update/.../3/18

However this API does not depend on the inter-call durations being equal, only
the sequence number is used to identify each request, and the
"duration_since_last request" parameter is only used to update (depending on the
plan type) a bucket or a CDR.

=head2 Returned values

Both calls return at least the following fields in JSON format:

  {
    estimated_duration => $maximum_call_duration_in_seconds,
    estimated_rate     => $estimated_per_minute_rate_for_the_call,
    estimated_cost     => $estimated_per_call_cost,
    currency           => $currency_unit (one of 'EUR', 'USD', etc),
  }

They might also return:

    # Prompt the user to confirm the call setup if the estimated_rate is at or above this value
    warning_rate       => $warning_rate,

    # If a bucket was used (there might be more than one, only the first one is returned).
    bucket_value       => $bucket_value,
    bucket_currency    => $bucket_currency
        if present: one of 'EUR', 'USD', etc;
        otherwise: bucket_value is measured in seconds


=cut

use JSON;
use AnyEvent;
use CCNQ::HTTPD;
use JSON;
use Logger::Syslog;
use CCNQ::Rating::Rate;

sub _session_ready {
  my ($params,$context) = @_;

  my $host = CCNQ::Install::realtime_estimator_rendezvous_host;
  my $port = CCNQ::Install::realtime_estimator_rendezvous_port;
  info("realtime_estimator: Starting web API on ${host}:${port}");
  $context->{httpd} = CCNQ::HTTPD->new (
    host => $host,
    port => $port,
  );

  $context->{httpd}->reg_cb(
    '/estimate' => sub {
      my ($httpd, $req) = @_;

      debug("realtime_estimator: Processing estimate");

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      if($path =~ m{^/estimate/(\w+)/(\w+)/(\w+)/(\d+)/(\d+)$}) {
        my $cbef = {
          account => $1,
          account_sub => $2,
          event_type => $3,
          from_e164 =>$4,
          to_e164 => $5,
        };
      } else {
        $req->respond([404,'Invalid request']);
        $httpd->stop_request;
        return;
      }

      if($req->method eq 'GET') {
        my $response = CCNQ::Rating::Rate::estimate_cbef($cbef);
        my $json_content = encode_json($response);
        $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);
      } else {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }

      $httpd->stop_request;
    },

    '/update' => sub {
      my ($httpd, $req) = @_;

      debug("realtime_estimator: Processing update");

      use URI;
      my $url = URI->new($req->url);
      my $path = $url->path;

      if($path =~ m{^/estimate/(\w+)/(\w+)/(\w+)/(\d+)/(\d+)/([^/]+)/(\d+)/(\d+)$}) {
        my $orig_cbef = {
          account                     => $1,
          account_sub                 => $2,
          event_type                  => $3,
          from_e164                   =>$4,
          to_e164                     => $5,

          call_uuid                   => $6,
          request_sequence            => $7,
          duration_since_last_request => $8,
        };
      } else {
        $req->respond([404,'Invalid request']);
        $httpd->stop_request;
        return;
      }

      if($req->method eq 'GET') {
        # Update the bucket(s), and/or create a CDR.
        my $flat_cbef = {%$orig_cbef}; # copy
        $flat_cbef->{event_type} .= "_intermediate";
        my $rate_cbef = new CCNQ::Rating::Event($flat_cbef);

        # Return immediately on invalid flat_cbef
        $rate_cbef or do {
          my $json_content = encode_json({ estimated_duration => 0 });
          $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);
        }

        CCNQ::Rating::Rate::rate_cbef($rate_cbef,$plan)->cb(sub{
          my $rated_cbef = CCNQ::AE::receive(@_);

          # Re-run the estimator to provide data about the remaining of the call.
          my $response = CCNQ::Rating::Rate::estimate_cbef($orig_cbef);
          my $json_content = encode_json($response);
          $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);
        });
      } else {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }

      $httpd->stop_request;
    },

  );
  return;
}

'CCNQ::Actions::realtime_estimator';
