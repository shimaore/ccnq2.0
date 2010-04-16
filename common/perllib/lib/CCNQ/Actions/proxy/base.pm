package CCNQ::Actions::proxy::base;
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

use Logger::Syslog;

use CCNQ;
use CCNQ::Util;
use CCNQ::Proxy;
use CCNQ::Proxy::Config;

sub _install {
  my ($params,$context) = @_;

  # MODEL: Which model is used for the local opensips system
  # Must be onre of the *.recipe names:
  #    complete-transparent
  #    complete
  #    inbound-proxy
  #    outbound-proxy
  #    registrar
  #    router-no-registrar
  #    router

  my $model = CCNQ::Util::first_line_of(CCNQ::Proxy::proxy_mode_file);
  die 'No proxy model found in '.CCNQ::Proxy::proxy_mode_file if !defined $model;
  my $template_dir = CCNQ::CCN;

  # We install opensips.cfg and opensips.sql into /etc/ccn/
  my $SRC = CCNQ::SRC;

  # Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
  info("Reconfiguring the local system");
  eval { CCNQ::Proxy::Config::configure_opensips($context,$model); };
  info($@) if $@;

  # Create the directory for the CDRs.
  use CCNQ::Proxy::Configuration;
  use File::Path;
  File::Path::mkpath([CCNQ::Proxy::Configuration::cdr_directory]);
  CCNQ::Util::execute('chown','opensips',CCNQ::Proxy::Configuration::cdr_directory);

  # Restart OpenSIPS using the new configuration.
  info("Restarting OpenSIPS");
  CCNQ::Util::execute('/bin/sed','-i','-e','s/^RUN_OPENSIPS=no$/RUN_OPENSIPS=yes/','/etc/default/opensips');
  CCNQ::Util::execute('/etc/init.d/opensips','restart');

  debug("Restarted OpenSIPS");

  CCNQ::Trace::install();
  return;
}

sub _session_ready {
  my ($params,$context) = @_;
  use CCNQ::XMPPAgent;
  CCNQ::XMPPAgent::join_cluster_room($context);
  return;
}

sub _dispatch {
  my ($action,$request,$context) = @_;

  die ['No action defined'] unless $action;

  my ($module,$command) = ($action =~ m{^(.*)/(delete|update|query)$});

  die ['Invalid action [_1]',$action]
    unless $module && $command;

  use CCNQ::Proxy::Configuration;
  return CCNQ::Proxy::Configuration::run_from_class($module,$command,$request->{params},$context);
}

sub dr_reload {
  my ($params,$context) = @_;
  use CCNQ::AE;
  return CCNQ::AE::execute($context,qw( /usr/sbin/opensipsctl fifo dr_reload ));
}

sub trusted_reload {
  my ($params,$context) = @_;
  use CCNQ::AE;
  return CCNQ::AE::execute($context,qw( /usr/sbin/opensipsctl fifo trusted_reload ));
}

sub trace {
  use CCNQ::Trace;
  CCNQ::Trace::run(shift->{params});
}

'CCNQ::Actions::proxy::base';
