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

package CCNQ::Proxy::domain;
use base qw(CCNQ::Proxy::Base);

=pod
    Domains list the names this system recognizes itself as. The domains
    are matched against the domain part of the SIP URI; calls are rejected
    if the domain is not listed here.
    <p>
    At a minimum you should list here:
    <ul>
    <li>the IP address of each server accepting SIP connections;
    <li>the DNS name(s) each server is known as;
    <li>if you defined SRV names for load-balancing or redundancy purposes, include
      the DNS names (withouth the _sip._udp prefix) here.
    </ul>

sub form
{
    my $self = shift;
    return (
        'Domain' => 'text',
    );
}

=cut

sub insert
{
    my ($self,$params) = @_;
    my $domain = $params->{domain};

    return ()
        unless defined $domain and $domain ne '';

    return (<<'SQL',[$domain]);
        INSERT INTO domain(domain) VALUES (?)
SQL
}

sub delete
{
    my ($self,$params) = @_;
    my $domain = $params->{domain};

    return ()
        unless defined $domain and $domain ne '';

    return (<<'SQL',[$domain]);
        DELETE FROM domain WHERE domain = ?
SQL
}

sub list
{
    my $self = shift;
    return (<<'SQL',[],undef);
        SELECT domain AS Domain FROM domain
        ORDER BY domain ASC
SQL
}

1;