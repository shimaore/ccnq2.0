package CCNQ::Actions::b2bua::services;
# Copyright (C) 2009  Stephane Alnet
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
use strict; use warnings;

=head1 OVERVIEW

The "services" type of node is a generic FreeSwitch node that will be
used to implement anything that is not a SBC.

For example:
- without origination: signaling-server, conferences, voicemail;
- with origination ("forwarding_sbc"): redirection, hunting, social-server.

Typically all these services are provided "on-a-stick", never sending signaling
traffic directly to a customer or carrier. These "services" server are
on the customer-side of the proxy. (Therefor they cannot be co-located with
any of that proxies' client-sbc. However they can be co-located with
carrier-sbc services.)

=cut

use CCNQ::B2BUA;
use CCNQ::Install;
use CCNQ::Util;
use AnyEvent;
use AnyEvent::DNS;
use Logger::Syslog;

sub _install  {
  my ($params,$context) = @_;

  my $dns_txt = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::txt( $dn, $cv );
    return ($cv->recv);
  };

  my $dns_a = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::a( $dn, $cv );
    return ($cv->recv);
  };

  my $b2bua_name = 'services';

  CCNQ::B2BUA::mk_dir(qw(autoload_configs));
  CCNQ::B2BUA::mk_dir(qw(sip_profiles));
  CCNQ::B2BUA::mk_dir(qw(dialplan));

  $context->{resolver} = AnyEvent::DNS::resolver;

  my $sip_profile_text = '';
  my $dialplan_text    = '';
  my $acl_text         = '';

  my @services_names = $dns_txt->( 'services-names',CCNQ::Install::fqdn );
  debug("Query TXT services-names -> ".join(',',@sbc_names));

  my ($stick_ip) = $dns_a->(CCNQ::Install::fqdn);

  for my $name (@sbc_names) {
    # Figure out whether we have all the data to configure this instance.
    # We need to have:
    #   profile   -- TXT record of the profile (templates) to use
    #   port      -- TXT record of the SIP port to use (externally)
    #                (The internal port is always $external_port + 10000.)
    #   egress    -- TXT record with the name of our egress proxy
    #   ingress   -- A records of servers authorized to talk to us

    my ($profile) = $dns_txt->( 'profile',$name,CCNQ::Install::fqdn );
    debug("Query TXT profile -> $profile") if defined $profile;

    error("Name $name has no profile recorded in DNS, skipping"),
    next if !defined($profile);

    CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${profile}.xml");
    CCNQ::B2BUA::copy_file($b2bua_name,qw( sip_profiles template ),"${profile}.xml");

    my $profile_template  = $profile;
    my $dialplan_template = $profile;

    debug("b2bua/$b2bua_name: Creating configuration for name $name / profile $profile.");

    my $port = $dns_txt->( 'port',$name,CCNQ::Install::fqdn );
    debug("Query TXT port -> $port") if defined $port;

    next unless defined($port) && defined($stick_ip);

    debug("b2bua/$b2bua_name: Found port $port");

    # Generate sip_profile entries
    $sip_profile_text .= <<"EOT";
      <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
      <X-PRE-PROCESS cmd="set" data="sip_port=${port}"/>
      <X-PRE-PROCESS cmd="set" data="sip_ip=${stick_ip}"/>
      <X-PRE-PROCESS cmd="include" data="template/${profile_template}.xml"/>

EOT

    # Generate ACLs
    my @ingress_ips = $dns_a->( 'ingress',$name,CCNQ::Install::fqdn );
    debug("b2bua/$b2bua_name: Found ingress IPs ".join(',',@ingress_ips));

    $acl_text .= qq(<list name="sbc-${name}" default="deny">);
    $acl_text .= join('',map { qq(<node type="allow" cidr="$_/32"/>) } @ingress_ips);
    $acl_text .= qq(</list>);

    # Generate dialplan entries
    my @egress = $dns_txt->( 'egress',$name,CCNQ::Install::fqdn );
    debug("b2bua/$b2bua_name: Found egress ".join(',',@egress));

    my $egress = shift(@egress) || '';
    $dialplan_text .= <<"EOT";
      <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_port=${port}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_ip=${stick_ip}"/>
      <X-PRE-PROCESS cmd="set" data="egress_target=${egress}"/>
      <X-PRE-PROCESS cmd="include" data="template/${dialplan_template}.xml"/>

EOT
  } # for $name

  my $sip_profile_file = CCNQ::B2BUA::install_dir(qw( sip_profiles ), "${b2bua_name}.xml" );
  CCNQ::Util::print_to($sip_profile_file,$sip_profile_text);

  my $acl_file = CCNQ::B2BUA::install_dir(qw( autoload_configs ), "${b2bua_name}.acl.xml" );
  CCNQ::Util::print_to($acl_file,$acl_text);

  my $dialplan_file = CCNQ::B2BUA::install_dir(qw( dialplan ), "${b2bua_name}.xml" );
  CCNQ::Util::print_to($dialplan_file,$dialplan_text);

  CCNQ::B2BUA::finish();
  return;
}

'CCNQ::Actions::b2bua::services';
