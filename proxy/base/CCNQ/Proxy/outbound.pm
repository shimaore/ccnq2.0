package CCNQ::Proxy::outbound;
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

use base qw(CCNQ::Proxy::Base);

=pod
    Each Target defined in a trunk set (for example for routing NPA,
    NPANXX, or customers) can be assigned parameters to control
    how the proxy access the target.
    <p>
    If the target requires authentication, enter the Realm, Login
    and Password required to proceed with authentication.
    <p>
    The target <em>must</em> be specified as IP:port, for example <tt>10.1.1.10:5060</tt> is a valid target.
=cut

sub form
{
    my $self = shift;
    return (
        'Target' => 'text',
        'Domain' => [ map { $_ => $_ } $self->list_of_domains ],
        'Realm' => 'text',
        'Login' => 'text',
        'Password' => 'text',
    );
}


sub insert
{
    my $self = shift;
    my %params = @_;
    my $target  = $params{target};
    my $domain  = $params{domain};
    my $uac_realm   = $params{realm};
    my $uac_user    = $params{login};
    my $uac_pass    = $params{password};

    return (
        $self->_avp_set($target,$domain,'uac_realm',$uac_realm),
        $self->_avp_set($target,$domain,'uac_user',$uac_user),
        $self->_avp_set($target,$domain,'uac_pass',$uac_pass),
    );
}

sub delete
{
    my $self = shift;
    my %params = @_;
    my $target  = $params{target};
    my $domain  = $params{domain};
    
    die "Target must be an IP:port" unless $target =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}$/;

    return (
        $self->_avp_set($target,$domain,'uac_realm',undef),
        $self->_avp_set($target,$domain,'uac_user',undef),
        $self->_avp_set($target,$domain,'uac_pass',undef),
    );
}

sub list
{
    my $self = shift;

    return (
        <<'SQL',
            SELECT DISTINCT value AS Target, domain AS Domain,
                    (SELECT value FROM avpops WHERE uuid = main.value AND attribute = ?) AS Realm,
                    (SELECT value FROM avpops WHERE uuid = main.value AND attribute = ?) AS Login,
                    (SELECT value FROM avpops WHERE uuid = main.value AND attribute = ?) AS Password
            FROM avpops main 
            WHERE attribute = ?
            ORDER BY value ASC
SQL
        [$self->avp->{uac_realm},$self->avp->{uac_user},$self->avp->{uac_pass},$self->avp->{tgw}],
        undef
    );
}

1;