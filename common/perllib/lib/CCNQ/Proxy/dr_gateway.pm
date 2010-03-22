package CCNQ::Proxy::dr_gateway;
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
    my $id          = $params->{id};
    my $address     = $params->{target};
    my $strip       = $params->{strip_digit} || 0;
    my $pri_prefix  = $params->{prefix} || '';
    my $uac_realm   = $params->{realm};
    my $uac_user    = $params->{login};
    my $uac_pass    = $params->{password};

    return ()
      unless defined $id && $id ne ''
           && defined $address && $address ne '';

    my @res;
    push @res,
        <<'SQL',[$id,'0',$address,$strip,$pri_prefix,'',''];
        INSERT INTO dr_gateways(id,type,address,strip,pri_prefix,attrs,description) VALUES (?,?,?,?,?,?)
SQL

    # XXX move the UAC data into the "attrs" field.
    return (
        @res,
        $self->_avp_set('uac',$address,'uac_realm',$uac_realm),
        $self->_avp_set('uac',$address,'uac_user',$uac_user),
        $self->_avp_set('uac',$address,'uac_pass',$uac_pass),
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $id = $params->{id};
    my $address = $params->{target};

    return ()
    unless defined($id) && $id ne ''
         && defined $address && $address ne '';

    my @res;
    push @res,
        <<'SQL',[$id,$address];
        DELETE FROM dr_gateways WHERE id = ? AND address = ?
SQL

    return (
        @res,
        $self->_avp_set('uac',$address,'uac_realm',undef),
        $self->_avp_set('uac',$address,'uac_user',undef),
        $self->_avp_set('uac',$address,'uac_pass',undef),
    );
}

1;
