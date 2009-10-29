use CCNQ::B2BUA;

use constant base_name => 'base';
use constant vars_xml => 'vars.xml';

{
  install => sub {
    my ($params,$context) = @_;

    CCNQ::B2BUA::install_file(base_name,vars_xml, sub {
      my $txt = shift;
      my $host_fqdn    = CCNQ::Install::fqdn;
      my $domain_name  = CCNQ::Install::domain_name;
      my $cluster_fqdn = CCNQ::Install::cluster_fqdn($context->cluster);
      return <<EOT . $txt;
        <X-PRE-PROCESS cmd="set" data="host_name=${host_fqdn}"/>
        <X-PRE-PROCESS cmd="set" data="cluster_name=${cluster_fqdn}"/>
        <X-PRE-PROCESS cmd="set" data="domain_name=${domain_name}"/>
EOT
    });

    # autoload_configs
    for my $name (qw(
      acl                    logfile
      cdr_csv                modules
      console                post_load_modules
      event_socket           sofia
      fifo                   switch
      local_stream           timezones
    )) {
      CCNQ::B2BUA::copy_file(base_name,qw( autoload_configs ),"${name}.conf.xml");
    }

    # dialplan/template
    for my $name (qw( )) {
      CCNQ::B2BUA::copy_file(base_name,qw( dialplan template ),"${name}.xml");
    }

    # sip_profile/template
    for my $name (qw( public sbc-media sbc-nomedia )) {
      CCNQ::B2BUA::copy_file(base_name,qw( sip_profiles template ),"${name}.xml");
    }
  },
}