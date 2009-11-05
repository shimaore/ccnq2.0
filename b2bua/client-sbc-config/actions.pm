use CCNQ::B2BUA;

{
  install => sub {
    my $b2bua_name = 'client-sbc-config';

    # dialplan
    for my $name (qw( plain plain-cnam )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan ),"${name}.xml");
    }

    # dialplan/template
    for my $name (qw( plain plain-cnam )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
    }

    # sip_profile
    for my $name (qw( plain plain-cnam )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( sip_profiles ),"${name}.xml");
    }

    # scripts
    for my $name (qw( cnam.pl )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( scripts ),${name});
    }
  },
}