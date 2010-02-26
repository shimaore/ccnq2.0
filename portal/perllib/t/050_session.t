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
use Test::More import => ['!pass'];

use_ok('Dancer');
set(session => 'Simple');

use_ok 'CCNQ::Portal::Site';
my $site = CCNQ::Portal::Site->new(default_locale => 'en-US');
ok($site,'Created site');

use_ok 'CCNQ::Portal::Session';
my $session = CCNQ::Portal::Session->new($site);
ok($session,'Created session');
ok(!$session->user,'No user before session start');
ok($session->locale,'Locale is present');
is($session->locale->id,'en-US','Locale selected is default');

$session->start('bob');
ok(!$session->expired,'expired too fast');
ok($session->user,'user created');
ok(!$session->expired,'expired too fast');
is($session->user->id,'bob','proper user');
ok(!$session->expired,'expired too fast');
ok($session->user->profile,'profile OK');
ok(!defined($session->user->profile->name),'name OK')
ok(!$session->expired,'expired too fast');

done_testing();
1;
