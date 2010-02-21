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

BEGIN {
  use_ok 'Dancer';
}
set(session => 'Simple');


use_ok 'CCNQ::Portal';
use_ok 'CCNQ::Portal::Site';
CCNQ::Portal->set_site(CCNQ::Portal::Site->new(default_locale => 'en-US'));

use_ok 'CCNQ::Portal::Session';
my $session = CCNQ::Portal::Session->new;
ok($session,'Created session');
ok(!$session->user,'No user before session start');
ok($session->locale,'Locale is present');
is($session->locale,'en-US','Locale selected is default');

# ok($session->start('bob')->user,'user created');
# is($session->user->id,'bob','proper user');

done_testing();
1;
