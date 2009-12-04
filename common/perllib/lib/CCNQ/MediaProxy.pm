package CCNQ::MediaProxy;
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

use CCNQ::Install;
use File::Spec;

use constant mediaproxy_directory => File::Spec->catfile(CCNQ::Install::SRC,qw( mediaproxy ));
use constant mediaproxy_install_conf => '/etc/mediaproxy'; # Debian
use constant mediaproxy_config => File::Spec->catfile(mediaproxy_install_conf,'config.ini');

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