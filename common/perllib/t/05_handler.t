# Tests for inclusion of different CCQN modules.

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
use Test::More;

# XXX make_couchdb_proxy is deprecated.
# XXX Unify "view" in node/provisioning/actions.pm and "get_request_status"
#     in manager/actions.pm

use_ok ("CCNQ::API::handler");
use_ok ("AnyEvent::CouchDB");
ok( CCNQ::API::handler::make_couchdb_proxy(
          {},couchdb('account_sub'),[qw(label plan)],[qw(label plan)],
        ), "make_couchdb_handler" );
done_testing();
1;
