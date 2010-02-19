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

use_ok ("CCNQ::AE::Run");

my $cv = CCNQ::AE::Run::attempt_run_module('node','status',{},{});
is_ok($cv,"attempt_run_module returned");
is(ref($cv),'CODE',"attempt_run_module returned CODE");

my $result = $cv->recv;
is_ok($result,"node/status returned");
is(ref($result),'HASH',"node/status returned HASH");
is($result->running,1,"node/status returned running");

done_testing();
1;