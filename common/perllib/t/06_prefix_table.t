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
use Test::More tests => 30;

use_ok ("CCNQ::Rating::Table");

my $table = new CCNQ::Rating::Table;
$table->insert( { prefix => '1',                value1 => 'abc', value2 => 'TYZ' } );
$table->insert( { prefix => '1234',             value1 => 'def', value2 => 'KJJ' } );
$table->insert( { prefix => '123456',           value1 => 'ghi', value2 => 'KJJ' } );
$table->insert( { prefix => '1234567890123456', value1 => 'jkl', value2 => 'KJJ' } );
$table->insert( { prefix => '124',              value1 => 'jkl', value2 => 'KLO' } );
$table->insert( { prefix => '253673',           value1 => 'mno', value2 => 'TYZ' } );

is( $table->lookup('1')->{value1}, 'abc' );
is( $table->lookup('1')->{value2}, 'TYZ' );
is( $table->lookup('12')->{value1}, 'abc' );
is( $table->lookup('123')->{value1}, 'abc' );
is( $table->lookup('1234')->{value1}, 'def' );
is( $table->lookup('12345')->{value1}, 'def' );
is( $table->lookup('123456')->{value1}, 'ghi' );
is( $table->lookup('1234567')->{value1}, 'ghi' );
is( $table->lookup('12345671998128')->{value1}, 'ghi' );
is( $table->lookup('12345678')->{value1}, 'ghi' );
is( $table->lookup('123456789')->{value1}, 'ghi' );
is( $table->lookup('1234567890')->{value1}, 'ghi' );
is( $table->lookup('12345678901')->{value1}, 'ghi' );
is( $table->lookup('123456789012')->{value1}, 'ghi' );
is( $table->lookup('1234567890123')->{value1}, 'ghi' );
is( $table->lookup('12345678901234')->{value1}, 'ghi' );
is( $table->lookup('123456789012345')->{value1}, 'ghi' );
is( $table->lookup('1234567890123456')->{value1}, 'jkl' );
is( $table->lookup('124')->{value1}, 'jkl' );
is( $table->lookup('12472819')->{value1}, 'jkl' );
is( $table->lookup('18981')->{value1}, 'abc' );
is( $table->lookup('19189128192812')->{value1}, 'abc' );
is( $table->lookup('2'), undef );
is( $table->lookup('25'), undef );
is( $table->lookup('253'), undef );
is( $table->lookup('2536'), undef );
is( $table->lookup('25367'), undef );
ok( $table->lookup('253673') );
ok( $table->lookup('253673')->{value1}, 'mno' );
ok( $table->lookup('253673837')->{value2}, 'TYZ' );

done_testing();
1;
