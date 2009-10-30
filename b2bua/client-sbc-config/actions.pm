use CCNQ::B2BUA;

{
  install => sub {
    my $b2bua_name = 'client-sbc-config';

    # dialplan
    for my $name (qw( plain )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan ),"${name}.xml");
    }

    # sip_profile
    for my $name (qw( plain )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( sip_profiles ),"${name}.xml");
    }
  },
}