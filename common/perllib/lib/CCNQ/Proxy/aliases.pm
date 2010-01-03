package CCNQ::Proxy::aliases;
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


=pod
    Aliases are used to define the following services:
    <ul>
    <li>N11 Easily Recognizable Codes
    <li>*XX Vertical Services Codes
    </ul>
    For Username, enter for example "911", and for Contact the SIP URI
    that emergency calls should follow (e.g. "sip:911@emergency.example.com").

sub form
{
    my $self = shift;
    return (
        'Username' => 'text',
        'Domain'   => 'text',
        'Target_Username' => 'text',
        'Target_Domain'   => 'text',
    );
}

=cut

sub insert
{
    my ($self,$params) = @_;

    my $alias_username = $params->{username};
    my $alias_domain   = $params->{domain};
    my $username = $params->{target_username};
    my $domain   = $params->{target_domain};

    return ()
        unless defined ($username) and $username ne ''
        and    defined ($domain)   and $domain ne ''
        and    defined ($alias_username) and $alias_username ne ''
        and    defined ($alias_domain)   and $alias_domain ne '';

    return (<<'SQL',[$username,$domain,$alias_username,$alias_domain]);
        INSERT INTO aliases(username,domain,alias_username,alias_domain) VALUES (?,?,?,?)
SQL
}

sub delete
{
    my ($self,$params) = @_;
    my $alias_username = $params->{username};
    my $alias_domain   = $params->{domain};

    return ()
        unless defined ($alias_username) and $alias_username ne ''
        and    defined ($alias_domain)   and $alias_domain ne '';

    return (<<'SQL',[$alias_username,$alias_domain]);
        DELETE FROM aliases WHERE alias_username = ? AND alias_domain = ?
SQL
}

sub list
{
    my $self = shift;
    return (<<'SQL',[],undef);
        SELECT alias_username AS username, alias_domain AS domain, username AS target_username, domain AS target_domain
        FROM aliases
        ORDER BY username, domain, alias_username, alias_domain ASC
SQL
}

1;