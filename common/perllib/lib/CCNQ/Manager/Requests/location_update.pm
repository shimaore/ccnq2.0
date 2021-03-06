package CCNQ::Manager::Requests::location_update;
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

# This is really only a template.
# A proper set of emergency-location creation pages should be
# created per deployment to handle national or local differences.

use CCNQ::Activities::Provisioning;
use CCNQ::Activities::Proxy;
use CCNQ::Manager;

=head1 PUT location
  account
  location
  cluster  # the outbound-proxy cluster
  domain
  routing_data
=cut

sub run {
  my $request = shift;

  return (
    CCNQ::Activities::Provisioning::update_location($request),
    CCNQ::Activities::Proxy->location_update({%$request, cluster_name => $request->{cluster}}),
    CCNQ::Manager::request_completed(),
  );
}

'CCNQ::Manager::Requests::location_update';
