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

# Are we in our normal source tree?
$ENV{'CCNQ_source_path'} = '../..' if -e '../../common/bin/xmpp_agent.pl';
ok($ENV{'CCNQ_source_path'},'Please specify CCNQ_source_path in the environment; for example run:  CCNQ_source_path=../.. make test ');

my $path = $ENV{'CCNQ_source_path'};

# find . -name 'actions.pm'
for my $name qw(
  ./b2bua/base/actions.pm
  ./b2bua/carrier-sbc-config/actions.pm
  ./b2bua/client-ocs-sbc/actions.pm
  ./b2bua/client-sbc-config/actions.pm
  ./manager/actions.pm
  ./mediaproxy/actions.pm
  ./mediaproxy/dispatcher/actions.pm
  ./mediaproxy/relay/actions.pm
  ./node/actions.pm
  ./node/api/actions.pm
  ./proxy/base/actions.pm
  ./proxy/inbound-proxy/actions.pm
  ./proxy/outbound-proxy/actions.pm
  ./proxy/router-no-registrar/actions.pm
) {
  require_ok ("$path/$name");
}

done_testing();
1;