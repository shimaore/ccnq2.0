package CCNQ::MediaProxy;

use CCNQ::Install;
use File::Spec;

use constant mediaproxy_directory => File::Spec->catfile(CCNQ::Install::SRC,qw( mediaproxy ));
use constant mediaproxy_install_conf => '/etc/mediaproxy'; # Debian
use constant mediaproxy_config => File::Spec->catfile(mediaproxy_install_conf,'config.ini');

use File::Spec;
use File::Copy;
use Logger::Syslog;

sub try_install {
  my ($src,$dst) = @_;
  if( -e $dst ) {
    info("Not overwriting existing $dst");
  } else {
    debug("Copying $src to $dst");
    copy($src,$dst) or warning("Copying $src to $dst failed: $!");
  }
}

sub install_default_key {
  my ($file) = @_;
  for my $prefix (qw( .crt .key )) {
    my $src = File::Spec->catfile(CCNQ::MediaProxy::mediaproxy_directory,$file,$file.$prefix);
    my $dst = File::Spec->catfile(CCNQ::MediaProxy::mediaproxy_install_conf,'tls',$file.$prefix);
    try_install($src,$dst);
  }
}

1;