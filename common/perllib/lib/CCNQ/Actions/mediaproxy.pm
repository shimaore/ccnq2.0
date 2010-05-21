package CCNQ::Actions::mediaproxy;
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

use CCNQ::MediaProxy;
use CCNQ::Util;
use File::Spec;
use File::Copy;

use Logger::Syslog;

use constant::defer dispatcher_file => sub { CCNQ::MediaProxy::mediaproxy_config.'.dispatcher' };
use constant::defer relay_file      => sub { CCNQ::MediaProxy::mediaproxy_config.'.relay' };

sub _install {
  my ($params,$context) = @_;

  for my $file (qw( ca.pem crl.pem )) {
    my $src = File::Spec->catfile(CCNQ::MediaProxy::mediaproxy_directory,$file);
    my $dst = File::Spec->catfile(CCNQ::MediaProxy::mediaproxy_install_conf,'tls',$file);
    CCNQ::MediaProxy::try_install($src,$dst);
  }
  my $dispatcher_file = dispatcher_file;
  my $relay_file      = relay_file;
  my $config_dispatcher = -f($dispatcher_file) ? CCNQ::Util::content_of($dispatcher_file) : '';
  my $config_relay      = -f($relay_file)      ? CCNQ::Util::content_of($relay_file)      : '';
  my $config = <<'EOT';
[TLS]
certs_path = /etc/mediaproxy/tls
;verify_interval = 300

[Database]
;dburi = mysql://mediaproxy:CHANGEME@localhost/mediaproxy
;sessions_table = media_sessions
;callid_column = call_id
;fromtag_column = from_tag
;totag_column = to_tag
;info_column = info

[Radius]
;config_file = /etc/opensips/radius/client.conf
;additional_dictionary = radius/dictionary

EOT
  CCNQ::Util::print_to(CCNQ::MediaProxy::mediaproxy_config,$config.$config_dispatcher.$config_relay);
  return;
}

sub _restart {
  CCNQ::Util::execute('/etc/init.d/mediaproxy-dispatcher','restart') if -f dispatcher_file;
  unlink(dispatcher_file);
  CCNQ::Util::execute('/etc/init.d/mediaproxy-relay',     'restart') if -f relay_file;
  unlink(relay_file);
  return;
}

'CCNQ::Actions::mediaproxy';
