package CCNQ::Proxy::Base;
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

use base qw(CCNQ::SQL::Base);

sub _init
{
    my $self = shift;
    my $challenge = pop;
    $self->{challenge} = $challenge;
    $self->SUPER::_init(@_);
}

sub list_of_servers
{
    return split ' ', ${configuration::sip_servers};
}

sub avp
{
    return
    {
        received_avp    => 42, # customarily

        # Outbound-trunks
        dr_ruri         => 155,
        dr_attrs        => 156,

        # Used by the UAC module
        uac_realm       => 10,
        uac_user        => 11,
        uac_pass        => 12,

        # by username
        src_subs        => 170, # IP to username
        # routing calls towards an endpoint
        user_ip         => 174, # IP to use if not registered and no CFNR
        user_port       => 175, # port to use if not registered and no CFNR
        user_srv        => 178, # used instead of IP if present
        strip_digit     => 179,
        # by username, force media-proxy
        user_force_mp   => 140,
        user_forbid_mp  => 141, # NOT implemented
        dest_domain     => 143, # override destination domain
        # by username, outbound routing
        user_outbound_route           => 144,
        ignore_default_outbound_route => 145,
        ignore_caller_outbound_route  => 146,
        check_from      => 147,
        # by username: auth (nanpa-style)
        allow_onnet     => 200,

        # by src_subs + number
        valid_from      => 100,

        # by number
        dst_subs        => 180, # DID to username
        cfa             => 181,
        cfnr            => 182,
        cfb             => 183,
        cfda            => 184,
        dst_domain      => 186, # DID to domain
        inv_timer       => 43,

        # cdr info
        src_type        => 190,
        dst_type        => 191,
        account         => 192,
        account_sub     => 193,
        number_account  => 194, # used in inbound-proxy
        number_account_sub => 195, # used in inbound-proxy

        # socket-info forwarding
        host_info       => 160,
        forwarding_sbc  => 161,
    }
}

sub address_groups
{
    return
    {
        proxy_servers   => 0,
    }
}

sub cdr_extra
{
    return
    [
        from_user       =>  '$fU',
        from_domain     =>  '$fd',
        ruri_user       =>  '$rU',
        ruri_domain     =>  '$rd',
        src_ip          =>  '$avp(host_info)',
        src_type        =>  '$avp(src_type)', # PSTN, ONNET
        dst_type        =>  '$avp(dst_type)', # ALIAS, ONNET
        src_subs        =>  '$avp(src_subs)',
        dst_subs        =>  '$avp(dst_subs)',
        account         =>  '$avp(account)',
        to_user         =>  '$tU',
        to_domain       =>  '$td',
        from_display    =>  '$fn',
        to_display      =>  '$tn',
        contact         =>  '$ct',
        src_port        =>  '$sp',
        user_agent      =>  '$ua',
        content_type    =>  '$cT',
    ];
}

# Default set of Radius attributes in the accounting module:
#   Acct-Status-Type  (Start, Stop, Failed)
#   Service-Type
#   Sip-Response-Code
#   Sip-Method
#   Event-Timestamp
#   Sip-From-Tag
#   Sip-To-Tag
#   Acct-Session-Id

# Example: (in dictionary.openser)
#   ATTRIBUTE OpenSER-Src-Type      240     string
#   ATTRIBUTE OpenSER-Dst-Type      241     string
#   ATTRIBUTE OpenSER-Src-Subs      242     string
#   ATTRIBUTE OpenSER-Dst-Subs      243     string


sub radius_extra
{
    return
    [
        'OpenSER-Src-Type'  =>  '$avp(src_type)', # PSTN, ONNET, ROUTE
        'OpenSER-Dst-Type'  =>  '$avp(dst_type)', # ALIAS, ONNET
        'OpenSER-Src-Subs'  =>  '$avp(src_subs)',
        'OpenSER-Dst-Subs'  =>  '$avp(dst_subs)',
    ];
}

sub _avp_delete_st { q(DELETE FROM avpops WHERE uuid = ? AND domain = ? AND attribute = ?) }
sub _avp_insert_st { q(INSERT INTO avpops(uuid,username,domain,attribute,value,type) VALUES (?,?,?,?,?,2)) }

sub _avp_set
{
    my $self = shift;
    my ($key,$domain,$attribute_name,$value) = @_;

    my $attribute_value = $self->avp->{$attribute_name};
    confess $attribute_name if not defined $attribute_value;

    if(defined $value)
    {
        return (_avp_delete_st,[$key,$domain,$attribute_value],
                _avp_insert_st,[$key,$key,$domain,$attribute_value,$value]);
    }
    else
    {
        return (_avp_delete_st,[$key,$domain,$attribute_value]);
    }
}

1;
