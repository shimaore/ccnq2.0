package CCNQ::Proxy::inbound;
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
    Inbound trunks. List the IP addresses of gateways or SBCs which
    are "trusted" (=not authenticated) and treated as PSTN calls.
    <p>
    Make sure to include Voicemail (VM) and Telephone User Interface
    (TUI) servers as well so that Message Waiting Indication (MWI) and
    call redirection can work properly.
    <p>
    The Source parameter must be an IP address.

sub form
{
    my $self = shift;
    return (
        'Source' => 'text',
    );
}

=cut

sub insert
{
    my ($self,$params) = @_;
    my $source  = $params->{source};

    return ()
        unless defined $source;
    
    die "Source must be an IP"
        unless $source =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/;

    return (
        <<'SQL',[$source],
            INSERT INTO trusted(src_ip,proto,from_pattern) VALUES (?,'any','^sip:.*$')
SQL
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $source = $params->{source};

    return ()
      unless defined $source;

    die "Source must be an IP"
        unless $source =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/;

    return (
        <<'SQL',[$source],
            DELETE FROM trusted WHERE src_ip = ?
SQL
    );
}

sub list
{
    my $self = shift;

    return (<<'SQL',[],undef);
      SELECT src_ip AS Source FROM trusted ORDER BY src_ip ASC
SQL
}

1;