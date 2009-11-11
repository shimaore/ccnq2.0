use CCNQ::B2BUA;
use CCNQ::Install;
use AnyEvent::DNS;
use File::Spec;
use File::Path;

{
  install => sub {
    use Logger::Syslog;

    my ($params,$context,$mcv) = @_;
    my $b2bua_name = 'carrier-sbc-config';

    debug("b2bua/carrier-sbc-config: Installing dialplan/template");
    for my $name (qw( dash level3 option-service transparent )) {
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
    <list name="proxies" default="deny">
      <!-- XXX Replace with "a.b.c.d/32" -->
      <node type="allow" cidr="0.0.0.0/0"/>
    </list>
EOT

    # sip_profile
    for my $name qw( dash-911 dash level3 option-service transparent ) {
      # Figure out whether we have all the data to configure the profile.
      # We need to have at least:
      #   port      -- TXT record of the SIP port to use (externally)
      #                         The internal port is always $external_port + 10000
      #   public    -- A record of our external SIP IP
      #   private   -- A record of our internal SIP IP
      # and zero or more of:
      #   ingress    -- A records with the IP address of the carrier's potential origination SBC
      #   egress     -- A record(s) with the IP address of the carrier's termination SBC

      my $extra = '';
      my $profile_template = 'sbc-nomedia';
      my $dialplan_template = $name;

      $extra = q(<X-PRE-PROCESS cmd="set" data="global_codec_prefs=PCMU@8000h@20i"/>),
      $dialplan_template = 'dash'
        if $name =~ /^dash/;
      $profile_template = 'sbc-media'
        if $name eq 'dash-911';

      debug("b2bua/carrier-sbc-config: Creating configuration for profile $name, if used.");

      my $port_dn = CCNQ::Install::catdns('port',$name,fqdn);
      my $port_cv = AnyEvent->condvar;
      AnyEvent::DNS::txt( $port_dn, $port_cv );
      my ($external_port) = $port_cv->recv;
      debug("Query TXT $port_dn -> $external_port") if defined $external_port;

      my $public_dn = CCNQ::Install::catdns('public',$name,fqdn);
      my $public_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( $public_dn, $public_cv );
      my ($public_ip) = $public_cv->recv;
      debug("Query A $public_dn -> $public_ip") if defined $public_ip;

      my $private_dn = CCNQ::Install::catdns('private',$name,fqdn);
      my $private_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( $private_dn, $private_cv );
      my ($private_ip) = $private_cv->recv;
      debug("Query A $private_dn -> $private_ip") if defined $private_ip;

      next unless defined($external_port) && defined($public_ip) && defined($private_ip);

      debug("b2bua/carrier-sbc-config: Found external port $external_port");
      my $internal_port = $external_port + 10000;
      debug("b2bua/carrier-sbc-config: Using internal port $internal_port");

      # Generate sip_profile entries
      $sip_profile_text .= <<"EOT";
        <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_port=${internal_port}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_port=${external_port}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_ip=${private_ip}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_ip=${public_ip}"/>
        ${extra}
        <X-PRE-PROCESS cmd="include" data="template/${profile_template}.xml"/>
EOT

      # Generate ACLs
      my $ingress_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( CCNQ::Install::catdns('ingress',$name,fqdn), $ingress_cv );
      my @ingress = $ingress_cv->recv;
      debug("b2bua/carrier-sbc-config: Found ingress IPs ".join(',',@ingress));

      $acl_text .= qq(<list name="sbc-${name}" default="deny">);
      $acl_text .= join('',map { qq(<node type="allow" cidr="$_/32"/>) } @ingress);
      $acl_text .= qq(</list>);

      # Generate dialplan entries
      my $egress_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( CCNQ::Install::catdns('egress',$name,fqdn), $egress_cv );
      my @egress = $egress_cv->recv;
      debug("b2bua/carrier-sbc-config: Found egress IPs ".join(',',@egress));

      # XXX Only one IP supported at this time.
      my $egress = shift @egress;
      $dialplan_text .= <<"EOT";
        <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_port=${internal_port}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_port=${external_port}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_ip=${private_ip}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_ip=${public_ip}"/>

        <X-PRE-PROCESS cmd="set" data="ingress_target=inbound-proxy.\$\${cluster_name}"/>
        <X-PRE-PROCESS cmd="set" data="egress_target=${egress}"/>
        <X-PRE-PROCESS cmd="include" data="template/${dialplan_template}.xml"/>
EOT
    } # for $name

    my $sip_profile_file = CCNQ::B2BUA::install_dir(qw( sip_profiles ), "${b2bua_name}.xml" );
    CCNQ::Install::print_to($sip_profile_file,$sip_profile_text);

    my $acl_file = CCNQ::B2BUA::install_dir(qw( autoload_configs ), "${b2bua_name}.acl.xml" );
    CCNQ::Install::print_to($acl_file,$acl_text);

    my $dialplan_file = CCNQ::B2BUA::install_dir(qw( dialplan ), "${b2bua_name}.xml" );
    CCNQ::Install::print_to($dialplan_file,$dialplan_text);

    CCNQ::B2BUA::finish();
    return;
  },
}
