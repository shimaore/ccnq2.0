package CCNQ::B2BUA;

use CCNQ::Install;
use File::Spec;
use File::Path;

use Logger::Syslog;

use constant b2bua_directory => File::Spec->catfile(CCNQ::Install::SRC,qw( b2bua ));

use constant freeswitch_install_conf => '/opt/freeswitch/conf'; # Debian

sub install_file {
  my $context = shift;
  my $cb = pop;
  my $function = shift;
  my @path = @_;
  my $src_dir = File::Spec->catfile(b2bua_directory,$function,qw( freeswitch conf ));
  my $src = File::Spec->catfile($src_dir,@path);
  my @dst_dir = (@path);
  pop @dst_dir;
  my $dst_dir = File::Spec->catfile(CCNQ::B2BUA::freeswitch_install_conf,@dst_dir);
  debug("Creating target directory $dst_dir");
  File::Path::mkpath([$dst_dir]);
  my $dst = File::Spec->catfile(CCNQ::B2BUA::freeswitch_install_conf,@path);
  debug("Installing $src as $dst");
  my $txt = CCNQ::Install::content_of($src);
  return error("No file $src") if !defined($txt);
  $txt = $cb->($txt) if $cb;
  CCNQ::Install::print_to($dst,$txt);
  CCNQ::Install::_execute($context,'chown','-R','freeswitch.daemon',freeswitch_install_conf);
}

sub copy_file {
  install_file(@_,undef);
}


1;