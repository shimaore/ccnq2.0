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

use_ok ("CCNQ::Trie");

my $table = CCNQ::Trie->new();
ok($table,'Table created');

$table->load([qw(1 123 1234 123456 1234567890123456 124 253673)]);

is( $table->lookup(''), undef );
is( $table->lookup('1'), '1' );
is( $table->lookup('12'), '1' );
is( $table->lookup('122'), '1' );
is( $table->lookup('123'), '123' );
is( $table->lookup('1234'), '1234' );
is( $table->lookup('12345'), '1234' );
is( $table->lookup('123456'), '123456' );
is( $table->lookup('1234567'), '123456' );
is( $table->lookup('12345671998128'), '123456' );
is( $table->lookup('12345678'), '123456' );
is( $table->lookup('123456789'), '123456' );
is( $table->lookup('1234567890'), '123456' );
is( $table->lookup('12345678901'), '123456' );
is( $table->lookup('123456789012'), '123456' );
is( $table->lookup('1234567890123'), '123456' );
is( $table->lookup('12345678901234'), '123456' );
is( $table->lookup('123456789012345'), '123456' );
is( $table->lookup('1234567890123456'), '1234567890123456' );
is( $table->lookup('12345678901234567'), '1234567890123456' );
is( $table->lookup('123456789012345678'), '1234567890123456' );
is( $table->lookup('1239'), '123' );
is( $table->lookup('124'), '124' );
is( $table->lookup('12472819'), '124' );
is( $table->lookup('18981'), '1' );
is( $table->lookup('19189128192812'), '1' );
is( $table->lookup('2'), undef );
is( $table->lookup('25'), undef );
is( $table->lookup('253'), undef );
is( $table->lookup('2536'), undef );
is( $table->lookup('25367'), undef );
is( $table->lookup('253673'), '253673' );
done_testing();
1;
