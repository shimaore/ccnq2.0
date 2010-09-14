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

use_ok ("CCNQ::AE");

my $cv1 = CCNQ::AE::execute({},'/bin/echo');
ok($cv1,'Execute returned condvar');
my $success1 = eval { $cv1->recv };
my $error1 = $@;
ok(!$error1,"Execute echo triggered error: $error1");
ok(!defined($success1),"Execute echo returned: ".CCNQ::AE::pp($success1));

my $cv2 = CCNQ::AE::execute({},'/bin/boolala');
ok($cv2,'Execute returned condvar');
my $success2 = eval { $cv2->recv };
my $error2 = $@;
ok(!$error2,"Execute boolala triggered error: $error2");
ok(defined($success2),"Execute echo returned: ".CCNQ::AE::pp($success2));

done_testing();
1;
