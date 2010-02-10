package CCNQ::Proxy::subscriber;
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
    A subscriber can be a line or trunk towards one of your downstream
    customers.
    <p>
    Subscribers are uniquely identified by their Username. (You can use
    the Inbound Numbers screen to assign DIDs to a subscriber.)
    <p>
    There are two methods to authenticate a subscriber when they place a call:
    <ul>
    <li>by the IP address of their endpoint;
    <li>using the Username and Password specified.
    </ul>
    Note that the originating port (UDP or TCP) for the SIP message is never matched;
    the port specified for the Subscriber is only used for calls going to that subscriber
    (see below).

    <p>
    If a subscriber cannot accept all digits in calls sent to them (for example 10 instead of 11 digits US), then
    use the Strip Digit field to specify how many digits should be stripped when sending calls to that
    subscriber.
    <p>
    Finally, you must indicate what type of calls this subscriber is
    authorized to place:
    <ul>
    <li>Local calls (on-net calls, or calls to NPANXX identified as "local");
    <li>Premium calls (calls to an NPA or an NXX identified as "premium");
    <li>Long Distance (LD) calls (non-local calls to a North-American number);
    <li>International calls (outside NANPA.com).
    </ul>
    All subscribers can place calls to N11 or *XX numbers.

    <p>
    For calls that must terminate at a subscriber, the following are tried in order:
    <ul>
    <li>the location specified in the registration information, if the subscriber is registered;
    <li>the location (SIP URI) specified as the CFNR (Call Forward on Non-Registered)
        for the destination Inbound Number if one is specified (see under Inbound Numbers);
    <li>as a last resort, the IP address and SIP port number specified for the Subscriber.
    </ul>


sub form
{
    my $self = shift;
    return (
        'Username'              => 'text',
        'Domain' => [ map { $_ => $_ } $self->list_of_domains ],
        'Password'              => 'text',
        'IP'                    => 'ip',
        'Port'                  => 'text',
        'SRV'                   => 'text',
        'Dest_Domain'           => 'text',
        'Strip_Digit'           => [''=>'None',1=>'Strip First Digit'],
        'Account'               => 'text',
        'Allow_OnNet'           => [1=>'Yes',0=>'No'],
        'Always_Proxy_Media'    => [0=>'No',1=>'Yes'],
        'Forwarding_SBC'        => [0=>'No',1=>'Yes'],
    );
}

=cut

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

    return ()
      unless defined $username and $username ne ''
      and    defined $domain   and $domain   ne '';

    my $challenge   = $self->{challenge};
    $challenge = $domain if $challenge eq '';

    my $allow_onnet   = $params->{allow_onnet} || 0;

    my $always_mp   = $params->{always_proxy_media} || 0;

    $ip = undef unless defined($ip) && $ip =~ /^[\d.]+$/;

    # A Forwarding SBC can only be authenticated by IP.
    return ()
      if $forwarding_sbc && !defined($ip);

    $strip_digit = undef unless defined($strip_digit) && $strip_digit =~ /^\d$/;

    $user_outbound_route = undef
      unless $user_outbound_route =~ /^\d+$/;

    my @res;
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
            INSERT INTO subscriber(username,domain) VALUES (?,?)
SQL
    }

    # Map IP to username (for IP-based authentication)
    if(defined $ip)
    {
        push @res, $self->_avp_set($ip,$domain,'src_subs',$username);
    }

    return (
        @res,
        $self->_avp_set($username,$domain,'account',$account),
        $self->_avp_set($username,$domain,'account_sub',$account_sub),
        $self->_avp_set($username,$domain,'user_ip',$ip),
        $self->_avp_set($username,$domain,'user_port',$port),
        $self->_avp_set($username,$domain,'user_srv',$srv),
        $self->_avp_set($username,$domain,'dest_domain',$dest_domain),
        $self->_avp_set($username,$domain,'strip_digit',$strip_digit),
        $self->_avp_set($username,$domain,'allow_onnet',$allow_onnet?1:undef),
        $self->_avp_set($username,$domain,'user_force_mp',$always_mp?1:undef),
        $self->_avp_set($username,$domain,'forwarding_sbc',$forwarding_sbc?1:undef),
        $self->_avp_set($username,$domain,'user_outbound_route',$user_outbound_route),
        $self->_avp_set($username,$domain,'ignore_caller_outbound_route',$ignore_caller_outbound_route?1:undef),
        $self->_avp_set($username,$domain,'ignore_default_outbound_route',$ignore_default_outbound_route?1:undef),
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $username = $params->{username};
    my $domain   = $params->{domain};
    my $ip       = $params->{ip};

    return ()
      unless defined $username and $username ne ''
      and    defined $domain   and $domain   ne '';

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
        $self->_avp_set($username,$domain,'dest_domain',undef),
        $self->_avp_set($username,$domain,'strip_digit',undef),
        $self->_avp_set($username,$domain,'allow_onnet',undef),
        $self->_avp_set($username,$domain,'user_force_mp',undef),
        $self->_avp_set($username,$domain,'forwarding_sbc',undef),
        $self->_avp_set($username,$domain,'user_outbound_route',undef),
        $self->_avp_set($username,$domain,'ignore_caller_outbound_route',undef),
        $self->_avp_set($username,$domain,'ignore_default_outbound_route',undef),
    );

    if(defined $ip)
    {
        push @res, $self->_avp_set($ip,$domain,'src_subs',undef);
    }

    return @res;
}

sub list
{
    my ($self,$params) = @_;

    my @where = ();
    my @where_values = ();
    my $account = $params->{account};
    push( @where, 'Account = ?' ), push( @where_values, $account )
        if defined $account and $account ne '';

    my $username = $params->{username};
    push( @where, 'Username = ?' ), push( @where_values, $username )
        if defined $username and $username ne '';

    my $domain = $params->{domain};
    push( @where, 'Domain = ?' ), push( @where_values, $domain )
        if defined $domain and $domain ne '';

    my $where = '';
    $where = 'HAVING '. join('AND', map { "($_)" } @where ) if @where;

    return (<<SQL,[$self->avp->{account},$self->avp->{src_subs},$self->avp->{user_port},$self->avp->{user_srv},$self->avp->{dest_domain},$self->avp->{strip_digit},$self->avp->{allow_onnet},$self->avp->{user_force_mp},$self->avp->{forwarding_sbc},$self->avp->{user_outbound_route},$self->avp->{ignore_caller_outbound_route},$self->avp->{ignore_default_outbound_route},$self->avp->{src_subs},@where_values],undef);
        SELECT username AS username,
               domain AS domain,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS account,
               (SELECT password FROM subscriber WHERE username = main.username AND domain = main.domain ) AS password,
               (SELECT uuid FROM avpops WHERE value = main.username AND domain = main.domain AND attribute = ?) AS ip,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS port,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS srv,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS dest_domain,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS strip_digit,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS allow_onnet,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS always_proxy_media,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS forwarding_sbc,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS outbound_route,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS ignore_caller_outbound_route,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS ignore_default_outbound_route,
               (SELECT contact FROM location WHERE username = main.username AND domain = main.domain ) AS contact,
               (SELECT received FROM location WHERE username = main.username AND domain = main.domain ) AS received,
               (SELECT user_agent FROM location WHERE username = main.username AND domain = main.domain ) AS user_agent,
               (SELECT expires FROM location WHERE username = main.username AND domain = main.domain ) AS expires
        FROM
        (
            SELECT username AS username, domain AS domain FROM subscriber main
            UNION
            SELECT value AS username, domain AS domain FROM avpops WHERE attribute = ?
        ) main
        $where
        ORDER BY username ASC
SQL
}

1;
