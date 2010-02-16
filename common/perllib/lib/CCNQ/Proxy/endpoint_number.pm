package CCNQ::Proxy::endpoint_number;
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

use base qw(CCNQ::Proxy::Base);

sub insert
{
    my ($self,$params) = @_;
    my $username    = $params->{username};
    my $domain      = $params->{domain};
    my $number      = $params->{number};

    return (
        $self->_avp_set("${username},${number}",$domain,'valid_from',1),
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $username    = $params->{username};
    my $domain      = $params->{domain};
    my $number      = $params->{number};

    return (
        $self->_avp_set("${username},${number}",$domain,'valid_from',undef),
    );
}

'CCNQ::Proxy::endpoint_number';
