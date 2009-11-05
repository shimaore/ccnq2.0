package CCNQ::SQL;
# Copyright (C) 2006, 2007  Stephane Alnet
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
#
use strict; use warnings;

use base qw(CCNQ::Object);

sub _init
{
    my $self = shift;
    my ($db) = @_;
    die "No database" unless $db;
    $self->{_db} = $db;
}

sub class { my $c = ref(shift); $c =~ s/^.*:://; return $c; }

sub _db  { shift->{_db} }

1;