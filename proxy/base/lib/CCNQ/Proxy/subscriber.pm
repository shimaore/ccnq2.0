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

package CCNQ::Proxy::subscriber;
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
    If a subscriber places a 7-digits call, the Default_NPA is prepended
    to that 7-digit number to form a 10-digit destination.
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
        'Recording'             => 'text',
        'Strip_Digit'           => [''=>'None',1=>'Strip First Digit'],
        'Default_NPA'           => 'text',
        'Account'               => 'text',
        'Allow_Local'           => [1=>'Yes',0=>'No'],
        'Allow_LD'              => [1=>'Yes',0=>'No'],
        'Allow_Premium'         => [1=>'Yes',0=>'No'],
        'Allow_International'   => [1=>'Yes',0=>'No'],
        'Always_Proxy_Media'    => [0=>'No',1=>'Yes'],
    );
}

=cut

sub new_precondition
{
    my ($self,$params) = @_;

    my $username = $params->{username};
    my $domain   = $params->{domain};

    warn("No username provided.") if not defined $username or $username eq '';
    warn("Username must be a-z0-9_-.") unless $username =~ /^[\w-]+$/;
    warn("No domain provided.") if not defined $domain or $domain eq '';

    my $count = 0;

    $count += $self->run_sql_once(<<'SQL',$username,$domain);
        SELECT COUNT(*) FROM subscriber WHERE username = ? AND domain = ?
SQL

    $count += $self->run_sql_once(<<'SQL',$username,$domain,$self->avp->{src_subs});
        SELECT COUNT(*) FROM avpops WHERE value = ? AND domain = ? AND attribute = ?
SQL

    return $count == 0;
}

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
    my $recording   = $params->{recording};
    my $strip_digit = $params->{strip_digit};
    my $default_npa = $params->{default_npa};
    my $account     = $params->{account};

    my $challenge   = $self->{challenge};
    $challenge = $domain if $challenge eq '';

    my $allow_local   = $params->{allow_local} || 0;
    my $allow_ld      = $params->{allow_ld} || 0;
    my $allow_premium = $params->{allow_premium} || 0;
    my $allow_intl    = $params->{allow_international} || 0;

    my $always_mp   = $params->{always_proxy_media} || 0;

    $ip = undef unless $ip =~ /^[\d.]+$/;

    $strip_digit = undef unless $strip_digit =~ /^\d$/;

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
        $self->_avp_set($username,$domain,'user_ip',$ip),
        $self->_avp_set($username,$domain,'user_port',$port),
        $self->_avp_set($username,$domain,'user_srv',$srv),
        $self->_avp_set($username,$domain,'user_recording',$recording),
        $self->_avp_set($username,$domain,'strip_digit',$strip_digit),
        $self->_avp_set($username,$domain,'default_npa',$default_npa),
        $self->_avp_set($username,$domain,'allow_local',$allow_local?1:undef),
        $self->_avp_set($username,$domain,'allow_ld',$allow_ld?1:undef),
        $self->_avp_set($username,$domain,'allow_premium',$allow_premium?1:undef),
        $self->_avp_set($username,$domain,'allow_intl',$allow_intl?1:undef),
        $self->_avp_set($username,$domain,'user_force_mp',$always_mp?1:undef),
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $username = $params->{username};
    my $domain   = $params->{domain};
    my $ip       = $params->{ip};

    my @res = (
        <<'SQL',[$username,$domain],
        DELETE FROM subscriber WHERE username = ? AND domain = ?
SQL
        # Should be redundant with the avp_set(src_subs) below.
        <<'SQL',[$username,$self->avp->{src_subs}],
        DELETE FROM avpops WHERE value = ? AND attribute = ?
SQL

        $self->_avp_set($username,$domain,'account',undef),
        $self->_avp_set($username,$domain,'user_ip',undef),
        $self->_avp_set($username,$domain,'user_port',undef),
        $self->_avp_set($username,$domain,'user_srv',undef),
        $self->_avp_set($username,$domain,'user_recording',undef),
        $self->_avp_set($username,$domain,'strip_digit',undef),
        $self->_avp_set($username,$domain,'default_npa',undef),
        $self->_avp_set($username,$domain,'allow_local',undef),
        $self->_avp_set($username,$domain,'allow_ld',undef),
        $self->_avp_set($username,$domain,'allow_premium',undef),
        $self->_avp_set($username,$domain,'allow_intl',undef),
        $self->_avp_set($username,$domain,'user_force_mp',undef),
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

    return (<<SQL,[$self->avp->{account},$self->avp->{src_subs},$self->avp->{user_port},$self->avp->{user_srv},$self->avp->{user_recording},$self->avp->{strip_digit},$self->avp->{default_npa},$self->avp->{allow_local},$self->avp->{allow_ld},$self->avp->{allow_premium},$self->avp->{allow_intl},$self->avp->{user_force_mp},$self->avp->{src_subs},@where_values],undef);
        SELECT username AS username,
               domain AS domain,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS account,
               (SELECT password FROM subscriber WHERE username = main.username AND domain = main.domain ) AS password,
               (SELECT uuid FROM avpops WHERE value = main.username AND domain = main.domain AND attribute = ?) AS ip,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS port,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS srv,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS recording,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS strip_digit,
               (SELECT value FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS default_npa,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS allow_local,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS allow_ld,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS allow_premium,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS allow_international,
               (SELECT COUNT(value) FROM avpops WHERE uuid = main.username AND domain = main.domain AND attribute = ?) AS always_proxy_media,
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
