package CCNQ::Proxy::local_number;
# Copyright (C) 2006, 2007  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict; use warnings;

use base qw(CCNQ::Proxy::Base);

=pod
    A number (DID or other) is mapped to an endpoint using
    that endpoint's Username. Numbers must start with a 1
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
    $account     = undef if defined($account) && $account     eq '';
    $account_sub = undef if defined($account) && $account_sub eq '';
    my $number_location   = $params->{number_location};

    return ()
      unless defined $number   and $number ne ''
      and    defined $domain   and $domain ne '';
    # Can't filter uniquely on username and username_domain, since e.g.
    # a number could only have a cfa, or an outbound_route (on outbound-proxy).

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
        $self->_avp_set($number,$domain,'number_location',$number_location),
    );
}

sub delete
{
    my ($self,$params) = @_;
    my $number  = $params->{number};
    my $domain  = $params->{domain};

    return ()
      unless defined $number   and $number ne ''
      and    defined $domain   and $domain ne '';

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
        $self->_avp_set($number,$domain,'number_location',undef),
    );
}

1;
