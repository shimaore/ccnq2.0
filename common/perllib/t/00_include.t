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

require_ok( 'CCNQ::Object' );
require_ok( 'AnyEvent::Watchdog::Util' );

require_ok( 'CCNQ::API::handler' );
require_ok( 'CCNQ::B2BUA' );

require_ok( 'CCNQ::HTTPD' );

# require_ok( 'CCNQ::I18N' );

require_ok( 'CCNQ::Install' );
require_ok( 'CCNQ::Manager' );
require_ok( 'CCNQ::MediaProxy' );
require_ok( 'CCNQ::XMPPAgent' );

require_ok( 'CCNQ::Proxy' );
require_ok( 'CCNQ::Proxy::aliases' );
require_ok( 'CCNQ::Proxy::Config' );
require_ok( 'CCNQ::Proxy::Configuration' );
require_ok( 'CCNQ::Proxy::domain' );
require_ok( 'CCNQ::Proxy::dr_gateway' );
require_ok( 'CCNQ::Proxy::dr_rule' );
require_ok( 'CCNQ::Proxy::inbound' );
require_ok( 'CCNQ::Proxy::local_number' );
require_ok( 'CCNQ::Proxy::subscriber' );

require_ok( 'CCNQ::SQL' );
require_ok( 'CCNQ::SQL::Base' );

# XXX Portal
# XXX Rating

done_testing();
1;
