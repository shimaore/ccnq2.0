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

require_ok( "CCNQ::Manager" );
ok(CCNQ::Manager::request_to_activity('aliases_delete'));
ok(CCNQ::Manager::request_to_activity('aliases_update'));
ok(CCNQ::Manager::request_to_activity('endpoint_delete'));
ok(CCNQ::Manager::request_to_activity('trace_query'));
ok(!CCNQ::Manager::request_to_activity('testing_with_an_unknown_weird_spooky_request'));

done_testing();
1;
