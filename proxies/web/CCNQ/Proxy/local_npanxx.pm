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

#
# For more information visit http://carrierclass.net/
#
use strict; use warnings;

package CCNQ::Proxy::local_npanxx;
use base qw(CCNQ::Proxy::Base);

sub doc
{
    return <<'HTML';

    Indicate any NPANXX (six digits prefix) that should be treated as
    "local call" for the purpose of call authorization.

HTML
}


sub _name { 'Local_NPANXX' }

sub form
{
    my $self = shift;
    return (
        $self->_name => 'text',
        'Domain' => [ map { $_ => $_ } $self->list_of_domains ],
    );
}

sub insert
{
    my $self = shift;
    my %params = @_;
    my $npa  = $params{lc($self->_name)};

    my $domain = $params{domain};

    return (
        $self->_avp_set($npa,$domain,lc($self->_name),1),
    );
}

sub delete
{
    my $self = shift;
    my %params = @_;
    my $npa  = $params{lc($self->_name)};

    my $domain = $params{domain};

    return (
        $self->_avp_set($npa,$domain,lc($self->_name),undef),
    );
}

sub list
{
    my $self = shift;
    my $name = $self->_name;

    return (<<SQL, [$self->avp->{lc($name)}], undef);
            SELECT DISTINCT uuid AS $name, domain AS "Domain"
            FROM avpops
            WHERE attribute = ?
            ORDER BY uuid ASC
SQL
}

1;