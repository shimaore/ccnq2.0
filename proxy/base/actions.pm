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

use CCNQ::Proxy;
use lib CCNQ::Proxy::proxy_base_lib;
use CCNQ::Proxy::Config;

{
  install => sub {
    my ($params,$context) = @_;

    use constant proxy_mode => 'proxy_mode';
    use constant proxy_mode_file => File::Spec->catfile(CCNQ::Install::CCN,proxy_mode);

    # MODEL: Which model is used for the local opensips system
    # Must be onre of the *.recipe names:
    #    complete-transparent
    #    complete
    #    inbound-proxy
    #    outbound-proxy
    #    registrar
    #    router-no-registrar
    #    router

    my $model = first_line_of(proxy_mode_file);
    die if !defined $model;
    my $template_dir = CCNQ::Install::CCN;

    # We install opensips.cfg and opensips.sql into /etc/ccn/
    my $SRC = CCNQ::Install::SRC;

    # Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
    info("Reconfiguring the local system");
    eval { CCNQ::Proxy::Config::configure_opensips($context,$model); };
    info($@) if $@;

    # Create the directory for the CDRs.
    use CCNQ::Proxy::Configuration;
    use File::Path;
    File::Path::mkpath([CCNQ::Proxy::Configuration::cdr_directory]);
    CCNQ::Install::execute('chown','opensips',CCNQ::Proxy::Configuration::cdr_directory);

    # Restart OpenSIPS using the new configuration.
    info("Restarting OpenSIPS");
    CCNQ::Install::execute('/bin/sed','-i','-e','s/^RUN_OPENSIPS=no$/RUN_OPENSIPS=yes/','/etc/default/opensips');
    CCNQ::Install::execute('/etc/init.d/opensips','restart');
    return;
  },

  _session_ready => sub {
    my ($params,$context) = @_;
    use CCNQ::XMPPAgent;
    debug("Proxy _session_ready");
    CCNQ::XMPPAgent::join_cluster_room($context);
    return;
  },

  _default => sub {
    my ($action,$request,$context) = @_;
    error("No action defined"), return unless $action;
    my ($module,$command) = ($action =~ m{^(.*)/(delete|update|query)$});
    error("Invalid action $action"), return unless $module && $command;

    debug("Ignoring response") if $request->{status};

    use CCNQ::Proxy::Configuration;
    my $cv = CCNQ::Proxy::Configuration::run_from_class($module,$command,$request->{params},$context);
    $context->{condvar}->cb($cv) if $cv;
    # _default must always return a value (undef means that the action was not handled)
    return {};
  },

  dr_reload => sub {
    my ($params,$context) = @_;
    CCNQ::Install::_execute($context,qw( /usr/sbin/opensipsctl fifo dr_reload ));
    return;
  },
  trusted_reload => sub {
    my ($params,$context) = @_;
    CCNQ::Install::_execute($context,qw( /usr/sbin/opensipsctl fifo trusted_reload ));
    return;
  },
}
