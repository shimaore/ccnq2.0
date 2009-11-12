use CCNQ::B2BUA;

{
  install => sub {
    my $b2bua_name = 'client-sbc-config';

    # acls
    for my $name ($b2bua_name) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( autoload_configs ),"${name}.acl.xml");
    }

    # dialplan
    for my $name ($b2bua_name) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan ),"${name}.xml");
    }

    # dialplan/template
    for my $name (qw( client-sbc-template ),
        map {($_.'-ingress',$_.'-egress')} qw( e164 france loopback transparent usa-cnam usa )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
    }

    # sip_profile
    for my $name ($b2bua_name) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( sip_profiles ),"${name}.xml");
    }

    # scripts
    for my $name (qw( cnam.pl )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( .. scripts ),${name});
    }

    return;
  },
}