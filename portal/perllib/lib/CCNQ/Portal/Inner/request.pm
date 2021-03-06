package CCNQ::Portal::Inner::request;
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

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::API;

use AnyEvent;
use CCNQ::AE;

=head1 /request/:request

Display the request.

=cut

use MIME::Base64;

get '/request/:request_id' => sub {
  var template_name => 'request';

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $request_id = params->{request_id};
  # XXX Authenticate (i.e. check that this user can legitimately access this request.)

  my $cv = AE::cv;
  CCNQ::API::request($request_id,$cv);
  my $res = CCNQ::AE::receive_docs($cv);

  my $pcap = $res->[2]->{response}->{result}->{pcap};
  if($pcap) {
    content_type 'binary/appplication';
    header 'Content-Disposition' => qq(attachment; filename="trace.pcap");
    return MIME::Base64::decode($pcap);
  } else {
    var result => $res;
    return CCNQ::Portal::content;
  }
};

'CCNQ::Portal::Inner::request';
