package CCNQ::Proxy::endpoint;
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

use Digest::MD5 qw(md5_hex);

sub insert
{
    my ($self,$params) = @_;
    my $username    = $params->{username};
    my $domain      = $params->{domain};
    my $password    = $params->{password};
    my $ip          = $params->{ip};
    my $port        = $params->{port};
    my $srv         = $params->{srv};
    my $via         = $params->{via};
    my $dest_domain = $params->{dest_domain};
    my $strip_digit = $params->{strip_digit};
    my $account     = $params->{account};
    my $account_sub = $params->{account_sub};
    my $forwarding_sbc = $params->{forwarding_sbc};
    my $user_outbound_route           = $params->{outbound_route};
    # caller_outbound_route is the one specified in local_number -> outbound_route
    my $ignore_caller_outbound_route  = $params->{ignore_caller_outbound_route};
    # default_outbound_route is outbound_route 0
    my $ignore_default_outbound_route = $params->{ignore_default_outbound_route};

    my $src_disabled = $params->{src_disabled};
    my $dst_disabled = $params->{dst_disabled};

    my $check_from = $params->{check_from};
    my $user_location = $params->{location};

    defined $username and $username ne ''
      or die('No username');
    defined $domain   and $domain   ne ''
      or die('No domain');

    my $challenge   = $self->{challenge};
    $challenge = $domain if $challenge eq '';

    my $allow_onnet   = $params->{allow_onnet} || 0;

    my $always_mp   = $params->{always_proxy_media} || 0;

    $ip = undef unless defined($ip) && $ip =~ /^[\d.]+$/;

    $forwarding_sbc && !defined($ip)
      and die('A Forwarding SBC can only be authenticated by IP.');

    $strip_digit = undef unless defined($strip_digit) && $strip_digit =~ /^\d$/;

    $user_outbound_route = undef
      unless $user_outbound_route =~ /^\d+$/;

    # forwarding_sbc can have two values:
    #   1 indicates the endpoint will forward the originator's IP address as part of Sock-Info data
    #     All data will then be loaded based on the originator's endpoint, on the endpoint that forwarded
    #     the information (e.g. account and accout_sub will be looked up by the proxy using that IP address).
    #   2 indicates the endpoint will forward the account and account_sub as part of the RURI.
    #     All data is still loaded using the forwarding endpoint's data; only the account and account_sub are
    #     substituted.
    $forwarding_sbc = undef
      unless $forwarding_sbc =~ /^\d$/;

    my @res;

    # Map IP to username (for IP-based authentication)
    if(defined $ip)
    {
        push @res, $self->_avp_set($ip,$domain,'src_subs',$username);
        push @res, $self->_avp_set($ip,$domain,'forwarding_sbc',$forwarding_sbc);
    }

    if( defined $password and $password ne '' )
    {
        push @res,
            <<'SQL',[$username,$domain,$password,md5_hex("$username:$challenge:$password"),md5_hex("$username\@$challenge:$challenge:$password")];
            INSERT INTO subscriber(username,domain,password,ha1,ha1b) VALUES (?,?,?,?,?)
SQL
    }
    else
    {
        push @res,
            <<'SQL',[$username,$domain];
            DELETE FROM subscriber WHERE username = ? AND domain = ?
SQL
    }

    return (
        $self->_avp_set($username,$domain,'account',$account),
        $self->_avp_set($username,$domain,'account_sub',$account_sub),
        $self->_avp_set($username,$domain,'user_ip',$ip),
        $self->_avp_set($username,$domain,'user_port',$port),
        $self->_avp_set($username,$domain,'user_srv',$srv),
        $self->_avp_set($username,$domain,'user_via',$via),
        $self->_avp_set($username,$domain,'dest_domain',$dest_domain),
        $self->_avp_set($username,$domain,'strip_digit',$strip_digit),
        $self->_avp_set($username,$domain,'allow_onnet',$allow_onnet?1:undef),
        $self->_avp_set($username,$domain,'src_disabled',$src_disabled?1:undef),
        $self->_avp_set($username,$domain,'dst_disabled',$dst_disabled?1:undef),
        $self->_avp_set($username,$domain,'user_force_mp',$always_mp?1:undef),
        $self->_avp_set($username,$domain,'user_outbound_route',$user_outbound_route),
        $self->_avp_set($username,$domain,'ignore_caller_outbound_route',$ignore_caller_outbound_route?1:undef),
        $self->_avp_set($username,$domain,'ignore_default_outbound_route',$ignore_default_outbound_route?1:undef),
        $self->_avp_set($username,$domain,'check_from',$check_from?1:undef),
        $self->_avp_set($username,$domain,'user_location',$user_location),
        @res,
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $username = $params->{username};
    my $domain   = $params->{domain};
    my $ip       = $params->{ip};

    defined $username and $username ne ''
      or die('No username');
    defined $domain   and $domain   ne ''
      or die('No domain');

    my @res = (
        <<'SQL',[$username,$domain],
        DELETE FROM subscriber WHERE username = ? AND domain = ?
SQL
        # Should be redundant with the avp_set(src_subs) below.
        <<'SQL',[$username,$self->avp->{src_subs}],
        DELETE FROM avpops WHERE value = ? AND attribute = ?
SQL

        $self->_avp_set($username,$domain,'account',undef),
        $self->_avp_set($username,$domain,'account_sub',undef),
        $self->_avp_set($username,$domain,'user_ip',undef),
        $self->_avp_set($username,$domain,'user_port',undef),
        $self->_avp_set($username,$domain,'user_srv',undef),
        $self->_avp_set($username,$domain,'user_via',undef),
        $self->_avp_set($username,$domain,'dest_domain',undef),
        $self->_avp_set($username,$domain,'strip_digit',undef),
        $self->_avp_set($username,$domain,'allow_onnet',undef),
        $self->_avp_set($username,$domain,'src_disabled',undef),
        $self->_avp_set($username,$domain,'dst_disabled',undef),
        $self->_avp_set($username,$domain,'user_force_mp',undef),
        $self->_avp_set($username,$domain,'user_outbound_route',undef),
        $self->_avp_set($username,$domain,'ignore_caller_outbound_route',undef),
        $self->_avp_set($username,$domain,'ignore_default_outbound_route',undef),
        $self->_avp_set($username,$domain,'check_from',undef),
        $self->_avp_set($username,$domain,'user_location',undef),
    );

    if(defined $ip)
    {
        push @res, $self->_avp_set($ip,$domain,'src_subs',undef);
        push @res, $self->_avp_set($ip,$domain,'forwarding_sbc',undef),
    }

    return @res;
}

1;
