# Tests for inclusion of different CCNQ::Portal modules.

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

require_ok( 'CCNQ::Portal::Site' );
require_ok( 'CCNQ::Portal::Formatter' ); # Obsolete, we use CGI::FormBuilder instead

require_ok( 'CCNQ::I18N' );
require_ok( 'CCNQ::Portal::Locale' );


require_ok( 'CCNQ::Portal' );
require_ok( 'CCNQ::Portal::Render' );

require_ok( 'CCNQ::Portal::Auth' );
require_ok( 'CCNQ::Portal::Session' );
require_ok( 'CCNQ::Portal::UserProfile' );
require_ok( 'CCNQ::Portal::User' );

# require_ok( 'CCNQ::Portal::LDAP' );
# require_ok( 'CCNQ::Portal::Auth::LDAP' );
require_ok( 'CCNQ::Portal::Auth::Dummy' );
require_ok( 'CCNQ::Portal::Auth::CouchDB' );

require_ok( 'CCNQ::Portal::Outer::AccountSelection' );
require_ok( 'CCNQ::Portal::Outer::LocaleSelection' );
require_ok( 'CCNQ::Portal::Outer::UserAuthentication' );
require_ok( 'CCNQ::Portal::Outer::UserRegistration' );
require_ok( 'CCNQ::Portal::Outer::UserUpdate' );
require_ok( 'CCNQ::Portal::Outer::Widget' );

require_ok( 'CCNQ::Portal::Inner::billing_plan' );
require_ok( 'CCNQ::Portal::Inner::provisioning' );
require_ok( 'CCNQ::Portal::Inner::request' );
require_ok( 'CCNQ::Portal::Inner::default' );

require_ok( 'CCNQ::Portal::Template::Plugin::loc' );

done_testing();
1;
