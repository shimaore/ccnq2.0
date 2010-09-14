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

use CCNQ::Install;
-e CCNQ::Install::couchdb_local_server_file or $ENV{'CCNQ_couchdb_local_server'} = '127.0.0.1';

require_ok( "CCNQ::Manager" );
is(ref(CCNQ::Manager::request_to_activity('domain_delete')->recv),'CODE');
is(ref(CCNQ::Manager::request_to_activity('domain_update')->recv),'CODE');
is(ref(CCNQ::Manager::request_to_activity('endpoint_delete')->recv),'CODE');
is(ref(CCNQ::Manager::request_to_activity('trace_query')->recv),'CODE');
ok(!defined(CCNQ::Manager::request_to_activity('testing_with_an_unknown_weird_spooky_request')->recv));

done_testing();
1;
