package CCNQ::Manager::Requests::table_prefix_delete;
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

use CCNQ::Billing;

sub run {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'delete_table_prefix',
      cluster_name => CCNQ::Billing::BILLING_CLUSTER_NAME,
      params => {
        map { $_ => $request->{$_} } qw( name prefix )
      }
    },
    CCNQ::Manager::request_completed(),
  );
}

'CCNQ::Manager::Requests::table_prefix_delete';
