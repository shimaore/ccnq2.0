# Tests for CCNQ::Install.

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

use Test::More;
require_ok( 'CCNQ::Install' );

$ENV{'CCNQ_cookie'} = 'ABCD';
is(CCNQ::Install::cookie(),'ABCD','cookie from environment');

$ENV{'CCNQ_host_name'} = 'test-host';
$ENV{'CCNQ_domain_name'} = 'private.example.net';
is(CCNQ::Install::fqdn(),'test-host.private.example.net','fqdn');

is(CCNQ::Install::manager_cluster_jid(),'manager@conference.private.example.net','manager cluster JID');

# Tests that rely on SRC
require_ok( 'AnyEvent' );

# Are we in our normal source tree?
$ENV{'CCNQ_source_path'} = '../..' if -e '../../common/bin/xmpp_agent.pl';
ok($ENV{'CCNQ_source_path'},'Please specify CCNQ_source_path in the environment; for example run:  CCNQ_source_path=../.. make test ');

my $sub = CCNQ::Install::attempt_run('node','status',undef,undef);
is(ref($sub), 'CODE', 'attempt_run for node/status');

my $cv = AnyEvent->condvar;
$sub->($cv);
my $r1 = $cv->recv;
ok(defined($r1),'node/status returned undef');
is(ref($r1),'HASH','node/status returns hash');
ok(exists($r1->{status}),'node/status returned CANCEL (probably could not find the script file)');
is($r1->{status},'completed','node/status failed');
is(ref($r1->{params}),'HASH','node/status returned params');
ok($r1->{params}->{running},'node/status');

done_testing();
1;