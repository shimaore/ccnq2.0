package CCNQ::Actions::b2bua::client_sbc_config;
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
use Logger::Syslog;

sub _install {
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

  my $b2bua_name = 'client-sbc-config';
  my $cluster_fqdn = CCNQ::Install::cluster_fqdn($params->{cluster_name});

  # dialplan/template
  debug("b2bua/$b2bua_name: Installing dialplan/template");
  for my $name (qw( client-sbc-template ),
      map {($_.'-ingress',$_.'-egress')} qw( e164 france loopback transparent transparent-cnam usa-cnam usa usa-cnam-bb )) {
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

  my @sbc_names = $dns_txt->( 'sbc-names',CCNQ::Install::fqdn );
  debug("Query TXT sbc-names -> ".join(',',@sbc_names));

  my ($stick_ip) = $dns_a->(CCNQ::Install::fqdn);

  for my $name (@sbc_names) {
    # Figure out whether we have all the data to configure this instance.
    # We need to have:
    #   profile   -- TXT record of the profile (templates) to use
    #   port      -- TXT record of the SIP port to use (externally)
    #                (The internal port is always $external_port + 10000.)
    #   egress-target -- TXT record with the name of our outbound-proxy (defaults to egress-proxy.${cluster_fqdn})
    #   ingress-target -- TXT record with the name of our customer-proxy (defaults to ingress-proxy.${cluster_fqdn})

    my ($profile) = $dns_txt->( 'profile',$name,CCNQ::Install::fqdn );

    error("Name $name has no profile recorded in DNS, skipping"),
    next if !defined($profile);

    my $profile_template = 'sbc-nomedia';
    my $dialplan_template = 'client-sbc-template';

    debug("b2bua/$b2bua_name: Creating configuration for name $name / profile $profile.");

    my ($external_port) = $dns_txt->( 'port',$name,CCNQ::Install::fqdn );

    next unless defined($external_port) && defined($stick_ip);

    debug("b2bua/$b2bua_name: Found external port $external_port");
    my $internal_port = $external_port + 10000;
    debug("b2bua/$b2bua_name: Using internal port $internal_port");

    # Generate sip_profile entries
    $sip_profile_text .= <<"EOT";
      <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
      <X-PRE-PROCESS cmd="set" data="internal_sip_port=${internal_port}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_port=${external_port}"/>
      <X-PRE-PROCESS cmd="set" data="internal_sip_ip=${stick_ip}"/>
      <X-PRE-PROCESS cmd="set" data="external_sip_ip=${stick_ip}"/>
      <X-PRE-PROCESS cmd="include" data="template/${profile_template}.xml"/>
EOT

    # Generate ACLs
    $acl_text .= qq(<list name="sbc-${name}" default="allow">);
    $acl_text .= qq(<node type="allow" cidr="0.0.0.0/0"/>);
    $acl_text .= qq(</list>);

    # Generate dialplan entries
    my @egress_target = $dns_txt->( 'egress-target',$name,CCNQ::Install::fqdn );
    debug("b2bua/$b2bua_name: Found egress target names ".join(',',@egress_target));

    my $egress_target = "egress-proxy.${cluster_fqdn}";
    $egress_target = shift(@egress_target) if $#egress_target >= 0;

    my @ingress_target = $dns_txt->( 'ingress-target',$name,CCNQ::Install::fqdn );
    debug("b2bua/$b2bua_name: Found ingress target names ".join(',',@ingress_target));

    my $ingress_target = "ingress-proxy.${cluster_fqdn}";
    $ingress_target = shift(@ingress_target) if $#ingress_target >= 0;

    $dialplan_text .= <<"EOT";
      <X-PRE-PROCESS cmd="set" data="ingress_target=${ingress_target}"/>
      <X-PRE-PROCESS cmd="set" data="egress_target=${egress_target}"/>

      <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
      <X-PRE-PROCESS cmd="include" data="template/${dialplan_template}.xml"/>
EOT
  } # for $name

  my $sip_profile_file = CCNQ::B2BUA::install_dir(qw( sip_profiles ), "${b2bua_name}.xml" );
  CCNQ::Util::print_to($sip_profile_file,$sip_profile_text);

  my $acl_file = CCNQ::B2BUA::install_dir(qw( autoload_configs ), "${b2bua_name}.acl.xml" );
  CCNQ::Util::print_to($acl_file,$acl_text);

  my $dialplan_file = CCNQ::B2BUA::install_dir(qw( dialplan ), "${b2bua_name}.xml" );
  CCNQ::Util::print_to($dialplan_file,$dialplan_text);

  # scripts
  for my $name (qw( cnam.pl )) {
    CCNQ::B2BUA::copy_file($b2bua_name,qw( .. scripts ),${name});
  }

  return;
}

'CCNQ::Actions::b2bua::client_sbc_config';
