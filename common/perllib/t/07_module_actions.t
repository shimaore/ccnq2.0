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

require_ok ("CCNQ::AE::Run");
require_ok ("AnyEvent");

# host_name is retruned with the response
$ENV{'CCNQ_host_name'} = 'test-host';

my $sub = CCNQ::AE::Run::attempt_run('node','status',{},{});
ok($sub,"attempt_run returned");
is(ref($sub),'CODE',"attempt_run returned CODE");

my $cv = AnyEvent->condvar;
ok($cv,"condvar worked");
$sub->($cv);
my $r1 = $cv->recv;
ok($r1,"node/status returned");
is(ref($r1),'HASH','node/status returns hash');
ok(exists($r1->{status}),'node/status returned CANCEL (probably could not find the script file)');
is($r1->{status},'completed','node/status failed: '.($r1->{error}||''));
is(ref($r1->{params}),'HASH','node/status returned params');
ok($r1->{params}->{running},'node/status');

done_testing();
1;