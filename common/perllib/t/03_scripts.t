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

# find . -name '*.pl'  --- with some restrictions
for my $name qw(
  ./b2bua/client-ocs-sbc/freeswitch/scripts/cnam.pl
  ./b2bua/client-sbc-config/freeswitch/scripts/cnam.pl
  ./common/bin/upgrade.pl
) {
  # require_ok ("$path/$name")  does not work.
  # I need the equivalent of "perl -wc".
  system(qq(perl -wc "${path}/${name}" > /dev/null 2>/dev/null)) == 0 || die "$name failed";
}

# Does not work with
#  ./common/bin/xmpp_agent.pl

done_testing();
1;