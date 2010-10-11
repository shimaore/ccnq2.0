package CCNQ::Proxy::dr_gateway;
# Copyright (C) 2006, 2007  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
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
    my $force_mp    = $params->{force_mp};
    my $description = $params->{description};

    return ()
      unless defined $id && $id ne ''
           && defined $address && $address ne '';

    $description = 'No description provided'
      unless defined $description;

    my %attrs = ();
    $attrs{realm}    = $uac_realm if defined($uac_realm) && $uac_realm ne '';
    $attrs{user}     = $uac_user  if defined($uac_user ) && $uac_user  ne '';
    $attrs{pass}     = $uac_pass  if defined($uac_pass ) && $uac_pass  ne '';
    $attrs{force_mp} = $force_mp  if defined($force_mp ) && $force_mp  ne '';

    my $attrs = join(';', map { "$_=$attrs{$_}" } keys(%attrs) );

    my @res;
    push @res,
        <<'SQL',[$id,'0',$address,$strip,$pri_prefix,$attrs,$description];
        INSERT INTO dr_gateways(gwid,type,address,strip,pri_prefix,attrs,description) VALUES (?,?,?,?,?,?,?)
SQL

    return (@res);
}

sub delete
{
    my ($self,$params) = @_;
    my $id = $params->{id};

    return ()
    unless defined($id) && $id ne '';

    my @res;
    push @res,
        <<'SQL',[$id];
        DELETE FROM dr_gateways WHERE gwid = ?
SQL

    return (@res);
}

1;
