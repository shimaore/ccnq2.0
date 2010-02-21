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

use_ok 'CCNQ::Portal::Locale';

my $locale = CCNQ::Portal::Locale->new('en-US');
ok($locale,'Created locale');
is($locale->id,'en-US','Stored locale');
ok($locale->lang,'Created lang');
ok($locale->loc('Test string'),'Loc works');
is($locale->loc('Test string 1234'),'Test string 1234','Unknown string works');

my $locale2 = CCNQ::Portal::Locale->new('fr-FR');
is($locale2->loc('Test String Example'),"Exemple de test",'Translation works');

done_testing();
1;
