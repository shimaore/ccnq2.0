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

package CCNQ::Proxy::outbound_route;
use base qw(CCNQ::Proxy::npa_route);

=pod
    The Route value is the Outbound Route name to be considered for routing.
    Rank must be an integer starting at 0 (first route) and 
    going up.
    <p>
    Target must be a "host:port" value indicating what host
    (IP address or DNS name) to use, and what port to use on
    the destination (use 0 to force DNS SRV resolution; otherwise
    in most cases the value should be 5060).
=cut

sub _prefix { 'R' }
sub _like     { my $self = shift; return $self->_prefix.('%'); }
sub _likenode { my $self = shift; return $self->_like().'/%'; }

sub insert
{
    my $self = shift;
    my %params = @_;
    my $node    = $params{node} || '';
    my $route   = $params{route};
    my $rank    = $params{rank};
    my $target  = $params{target};
    my $domain  = $params{domain};
    
    die "Invalid Route" unless $route =~ /^[a-z]\w+$/i;
    die "Invalid Rank"  unless $rank =~ /^\d+$/;

    my $uuid        = $self->_prefix . $route . chr(ord('A')+$rank);
    my $next_uuid   = $self->_prefix . $route . chr(ord('A')+$rank+1);

    $uuid        .= '/'.$node if $node;
    $next_uuid   .= '/'.$node if $node;

    return (
        $self->_avp_set($uuid,$domain,'gwadv',$next_uuid),
        $self->_avp_set($uuid,$domain,'tgw',$target),
    );
}

sub list
{
    my $self = shift;

    our $prefix_length = length($self->_prefix);

    return (
        <<'SQL',
            SELECT uuid AS uuid, value AS Target, domain AS Domain
            FROM avpops main
            WHERE (uuid LIKE ? OR uuid LIKE ?) AND attribute = ?
            ORDER BY uuid ASC
SQL
        [$self->_like(),$self->_likenode(),$self->avp->{tgw}],
        sub {
            my ($content,$names) = @_;
            my $uuid = $content->[0];
            my $domain = $content->[1];
            my $node = '';
            $uuid = $1, $node = $2 if $uuid =~ m{^([^/]+)/(.*)$};

            return
            # Content
            [
                $node,
                $domain,
                substr($uuid,1,length($uuid)-2),
                ord(substr($uuid,length($uuid)-1,1))-ord('A'),
                $content->[2],
            ],
            # Names
            [qw(Node Route Rank Target)]
            ;
        }
    );
}

1;
