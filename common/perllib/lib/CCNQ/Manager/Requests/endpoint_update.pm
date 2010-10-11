package CCNQ::Manager::Requests::endpoint_update;
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

use CCNQ::Activities::Proxy;
use CCNQ::Activities::Provisioning;
use CCNQ::Activities::Billing;
use CCNQ::Manager;

sub run {
  my $request = shift;
  $request->{endpoint} = join('@',$request->{username},$request->{domain});
  # Return list of activities required to complete this request.
  return (
    CCNQ::Activities::Provisioning::update_endpoint($request),
    CCNQ::Activities::Proxy->endpoint_update({%$request, cluster_name => $request->{cluster}}),
    CCNQ::Activities::Billing::partial_day($request,'endpoint_update'),
    CCNQ::Manager::request_completed(),
  );
}

'CCNQ::Manager::Requests::endpoint_update';
