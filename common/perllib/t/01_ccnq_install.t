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
use strict; use warnings;
use Test::More;
require_ok( 'CCNQ::Install' );
require_ok( 'CCNQ::AE::Run' );

$ENV{'CCNQ_cookie'} = 'ABCD';
is(CCNQ::Install::cookie(),'ABCD','cookie from environment');

$ENV{'CCNQ_host_name'} = 'test-host';
$ENV{'CCNQ_domain_name'} = 'private.example.net';
is(CCNQ::Install::fqdn(),'test-host.private.example.net','fqdn');

is(CCNQ::Install::manager_cluster_jid(),'manager@conference.private.example.net','manager cluster JID');

# Tests that rely on SRC
require_ok( 'AnyEvent' );

my $sub = CCNQ::AE::Run::attempt_run('node','status',undef,undef);
is(ref($sub), 'CODE', 'attempt_run for node/status');

my $cv = $sub->();
ok($cv,'node/status did not return a condvar');
my $r1 = $cv->recv;
ok(defined($r1),'node/status returned undef');
is(ref($r1),'HASH','node/status returns hash');
ok(exists($r1->{running}),'node/status returned CANCEL (probably could not find the script file)');
is($r1->{running},1,'node/status failed');

done_testing();
1;