package CCNQ::Actions::b2bua::carrier_sbc_config;
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

use CCNQ::B2BUA;
use CCNQ::Install;
use CCNQ::Util;
use AnyEvent;
use AnyEvent::DNS;
use File::Spec;
use File::Path;

use Logger::Syslog;

sub _install {
  my ($params,$context) = @_;

  my $b2bua_name = 'carrier-sbc-config';
  my $cluster_fqdn = CCNQ::Install::cluster_fqdn($params->{cluster_name});

  debug("b2bua/$b2bua_name: Installing dialplan/template");
  for my $name (qw( dash-e164 dash level3 option-service transparent )) {
    CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
  }

  CCNQ::B2BUA::mk_dir(qw(autoload_configs));
  CCNQ::B2BUA::mk_dir(qw(sip_profiles));
  CCNQ::B2BUA::mk_dir(qw(dialplan));

  $context->{resolver} = AnyEvent::DNS::resolver;

  my $sip_profile_text = '';
  my $dialplan_text    = '';
  my $acl_text         = <<'EOT';
  <!-- The "proxies" ACL should contain one entry for each OpenSIPS proxy host. -->
  <!-- This should complement, not replace, a firewall or iptables. -->

  <!-- List the IP addresses of each OpenSIPS egress server. -->
  <!-- XXX Replace with "deny" -->
  <list name="proxies" default="allow">
    <!-- XXX Replace with "a.b.c.d/32" -->
    <node type="allow" cidr="0.0.0.0/0"/>
  </list>
EOT

  my $sbc_names_dn = CCNQ::Install::catdns('sbc-names',CCNQ::Install::fqdn);
  my $sbc_names_cv = AE::cv;
  AnyEvent::DNS::txt( $sbc_names_dn, $sbc_names_cv );
  my @sbc_names = $sbc_names_cv->recv;
  debug("Query TXT $sbc_names_dn -> ".join(',',@sbc_names));

  my $external_ip = CCNQ::Install::external_ip;
  my $internal_ip = CCNQ::Install::internal_ip;

  for my $name (@sbc_names) {
    # Figure out whether we have all the data to configure this instance.
    # We need to have at least:
    #   profile   -- TXT record of the profile (templates) to use
    #   port      -- TXT record of the SIP port to use (externally)
    #                (The internal port is always $external_port + 10000.)
    #   external  -- A record of (host's) external SIP IP
    #   internal  -- A record of (host's) internal SIP IP
    # and zero or more of:
    #   ingress    -- A records with the IP address of the carrier's potential origination SBC
    #   egress     -- A record(s) with the IP address of the carrier's termination SBC

    my $profile_dn = CCNQ::Install::catdns('profile',$name,CCNQ::Install::fqdn);
    my $profile_cv = AE::cv;
    AnyEvent::DNS::txt( $profile_dn, $profile_cv );
    my ($profile) = $profile_cv->recv;
    debug("Query TXT $profile_dn -> $profile") if defined $profile;

    error("Name $name has no profile recorded in DNS (TXT $profile_dn), skipping"),
    next if !defined($profile);

    my $extra = '';
    my $profile_template = 'sbc-nomedia';
    my $dialplan_template = $profile;

    $extra = q(<X-PRE-PROCESS cmd="set" data="global_codec_prefs=PCMU@8000h@20i"/>),
    $dialplan_template = 'dash',
    $profile_template = 'sbc-media'
      if $name eq 'dash-911';

    debug("b2bua/$b2bua_name: Creating configuration for name $name / profile $profile.");

    my $port_dn = CCNQ::Install::catdns('port',$name,CCNQ::Install::fqdn);
    my $port_cv = AE::cv;
    AnyEvent::DNS::txt( $port_dn, $port_cv );
    my ($external_port) = $port_cv->recv;
    debug("Query TXT $port_dn -> $external_port") if defined $external_port;

    next unless defined($external_port) && defined($external_ip) && defined($internal_ip);

    debug("b2bua/$b2bua_name: Found external port $external_port");
    my $internal_port = $external_port + 10000;
    debug("b2bua/$b2bua_name: Using internal port $internal_port");

    # Generate sip_profile entries
    $sip_profile_text .= <<"EOT";
      <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
      <X-PRE-PROCESS cmd="set" data="internal_sip_port=${internal_port}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_port=${external_port}"/>
      <X-PRE-PROCESS cmd="set" data="internal_sip_ip=${internal_ip}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_ip=${external_ip}"/>
      ${extra}
      <X-PRE-PROCESS cmd="include" data="template/${profile_template}.xml"/>
EOT

    # Generate ACLs
    my $ingress_cv = AE::cv;
    AnyEvent::DNS::a( CCNQ::Install::catdns('ingress',$name,CCNQ::Install::fqdn), $ingress_cv );
    my @ingress = $ingress_cv->recv;
    debug("b2bua/$b2bua_name: Found ingress IPs ".join(',',@ingress));

    $acl_text .= qq(<list name="sbc-${name}" default="deny">);
    $acl_text .= join('',map { qq(<node type="allow" cidr="$_/32"/>) } @ingress);
    $acl_text .= qq(</list>);

    # Generate dialplan entries
    my $egress_cv = AE::cv;
    AnyEvent::DNS::a( CCNQ::Install::catdns('egress',$name,CCNQ::Install::fqdn), $egress_cv );
    my @egress = $egress_cv->recv;
    debug("b2bua/$b2bua_name: Found egress IPs ".join(',',@egress));

    # XXX Only one IP supported at this time.
    my $egress = shift @egress;
    $dialplan_text .= <<"EOT";
      <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
      <X-PRE-PROCESS cmd="set" data="internal_sip_port=${internal_port}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_port=${external_port}"/>
      <X-PRE-PROCESS cmd="set" data="internal_sip_ip=${internal_ip}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_ip=${external_ip}"/>

      <X-PRE-PROCESS cmd="set" data="ingress_target=inbound-proxy.${cluster_fqdn}"/>
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

'CCNQ::Actions::b2bua::carrier_sbc_config';
