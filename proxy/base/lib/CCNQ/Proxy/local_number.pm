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

package CCNQ::Proxy::local_number;
use base qw(CCNQ::Proxy::Base);

=pod
    A number (DID or other) is mapped to a subscriber using
    that subscriber's Username. Numbers must start with a 1
    and be followed by 10 digits to be used.

    Additionally, you can define Call Forward All (CFA),
    Call Forward on Not Registered (CFNR), Call Forward on
    Busy (CFB) and Call Forward Don't Answer (CFDA) targets
    as SIP URIs.
    <p>
    For example, if you want calls to go to a voicemail system
    on Busy, enter a SIP URI targetting your voicemail system
    for the CFB field, such as
    "sip:vmb-username@voicemail.example.com".
    <p>
    The CFDA_Timeout parameter allows you to control the duration
    a destination is tried (ringing) before the call is considered
    Not Answered. (The default value is 120 seconds.)

sub form
{
    my $self = shift;
    return (
        'Number' => 'text',
        'Domain' => [ map { $_ => $_ } $self->list_of_domains ],
        'Username' => 'text',
        'Username_Domain' => [ map { $_ => $_ } $self->list_of_domains ],
        'CFA' => 'text',
        'CFNR' => 'text',
        'CFB' => 'text',
        'CFDA' => 'text',
        'CFDA_Timeout' => 'integer',
        'Outbound_Route' => 'text',
    );
}

=cut


sub insert
{
    my ($self,$params) = @_;
    my $number            = $params->{number};
    my $domain            = $params->{domain};
    my $username          = $params->{username};
    my $username_domain   = $params->{username_domain};
    my $cfa               = $params->{cfa} || undef;
    my $cfnr              = $params->{cfnr} || undef;
    my $cfb               = $params->{cfb} || undef;
    my $cfda              = $params->{cfda} || undef;
    my $cfda_timeout      = $params->{cfda_timeout} || undef;
    my $outbound_route    = $params->{outbound_route} || undef;
    # These are mostly useful in the inbound-proxy.
    # Also note that they are only used for inbound calls, never for outbound calls.
    my $account           = $params->{account};
    my $account_sub       = $params->{account_sub};
    $account     = undef if $account     eq '';
    $account_sub = undef if $account_sub eq '';

    return () unless defined $number and $number ne '';
    return () unless defined $username and $username ne '';

    my @result = ();
    if(defined $outbound_route) {
      push @result, (<<'SQL',[$number,$domain,$outbound_route]);
        INSERT INTO dr_groups(username,domain,groupid) VALUES (?,?,?);
SQL
    } else {
      push @result, (<<'SQL',[$number,$domain]);
        DELETE FROM dr_groups WHERE username = ? AND domain = ?;
SQL
    }

    return (
        @result,
        $self->_avp_set($number,$domain,'dst_subs',$username),
        $self->_avp_set($number,$domain,'dst_domain',$username_domain),
        $self->_avp_set($number,$domain,'cfa',$cfa),
        $self->_avp_set($number,$domain,'cfnr',$cfnr),
        $self->_avp_set($number,$domain,'cfb',$cfb),
        $self->_avp_set($number,$domain,'cfda',$cfda),
        $self->_avp_set($number,$domain,'inv_timer',$cfda_timeout),
        $self->_avp_set($number,$domain,'number_account',$account),
        $self->_avp_set($number,$domain,'number_account_sub',$account_sub),
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $number  = $params->{number};
    my $domain  = $params->{domain};

    my @result = (<<'SQL',[$number,$domain]);
      DELETE FROM dr_groups WHERE username = ? AND domain = ?;
SQL
    return (
        @result,
        $self->_avp_set($number,$domain,'dst_subs',undef),
        $self->_avp_set($number,$domain,'dst_domain',undef),
        $self->_avp_set($number,$domain,'cfa',undef),
        $self->_avp_set($number,$domain,'cfnr',undef),
        $self->_avp_set($number,$domain,'cfb',undef),
        $self->_avp_set($number,$domain,'cfda',undef),
        $self->_avp_set($number,$domain,'inv_timer',undef),
        $self->_avp_set($number,$domain,'number_account',undef),
        $self->_avp_set($number,$domain,'number_account_sub',undef),
    );
}

sub list
{
    my ($self,$params) = @_;
    my $number = $params->{number};

    my $where = '';
    if(defined $number and $number =~ /^\d+$/)
    {
        $where .= q( AND uuid LIKE '%).$number.q(%');
    }

    return (
        <<SQL,
            SELECT DISTINCT uuid AS number, domain AS domain, value AS username,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS username_domain,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS cfa,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS cfnr,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS cfb,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS cfda,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS cfda_timeout,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS account,
                    (SELECT value FROM avpops WHERE uuid = main.uuid AND domain = main.domain AND attribute = ?) AS account_sub,
                    (SELECT groupid FROM dr_groups WHERE username = main.uuid AND domain = main.domain) AS outbound_route
            FROM avpops main
            WHERE attribute = ? $where
            ORDER BY uuid, value ASC
SQL
        [$self->avp->{dst_domain},$self->avp->{cfa},$self->avp->{cfnr},$self->avp->{cfb},$self->avp->{cfda},$self->avp->{inv_timer},$self->avp->{number_account},$self->avp->{number_account_sub},$self->avp->{dst_subs}],
        undef
    );
}

1;