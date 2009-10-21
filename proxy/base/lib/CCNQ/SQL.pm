package CCNQ::Proxy::SQL;
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
    my ($json,$db) = @_;
    $self->{_db}       = $db;
}

sub class { my $c = ref(shift); $c =~ s/^.*:://; return $c; }

sub _db  { shift->{_db} }

sub run_sql
{
    my $self = shift;
    while(my $sql = shift)
    {
        my $params = shift;
        $self->run_sql_command($sql,$params);
    }
}

sub run_sql_once
{
    my $self = shift;
    my $sth = $self->run_sql_command(@_);
    return undef if not defined $sth;
    my $val = $sth->fetchrow_arrayref->[0];
    $sth->finish();
    $sth = undef;
    return $val;
}

sub run_sql_command
{
    my $self = shift;
    my $cmd = shift;
    my $params = shift || [];
    my $sth = $self->_db->prepare($cmd);

    if(!$sth || !$sth->execute(@{$params}))
    {
        use Carp;
        confess("$cmd(".join(',',@{$params})."): ".$self->_db->errstr);
    }

    warn "$cmd(".join(',',@{$params}).")\n";
    return $sth;
}

1;