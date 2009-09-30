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

#
# For more information visit http://carrierclass.net/
#
use strict; use warnings;

use base qw(CCNQ::Proxy::Base);

sub doc
{
    return <<'HTML';
    Aliases are used to define the following services:
    <ul>
    <li>N11 Easily Recognizable Codes
    <li>*XX Vertical Services Codes
    </ul>
    For Username, enter for example "911", and for Contact the SIP URI
    that emergency calls should follow (e.g. "sip:911@emergency.example.com").
HTML
}

sub form
{
    my $self = shift;
    return (
        'Username' => 'text',
        'Contact'  => 'text',
    );
}

sub insert
{
    my $self = shift;
    my %params = @_;
    
    my $username = $params{username};
    my $contact = $params{contact};
    
    return ()
        unless defined $username and $username ne ''
        and    defined $contact and $contact ne '';
    
    return (<<'SQL',[$username,$contact]);
        INSERT INTO aliases(username,domain,contact) VALUES (?,'',?)
SQL
}

sub delete
{
    my $self = shift;
    my %params = @_;
    my $username = $params{username};
    my $contact = $params{contact};

    return (<<'SQL',[$username,$contact]);
        DELETE FROM aliases WHERE username = ? AND contact = ?
SQL
}

sub list
{
    my $self = shift;
    return (<<'SQL',[],undef);
        SELECT username AS Username, contact AS Contact 
        FROM aliases
        ORDER BY username ASC
SQL
}

1;