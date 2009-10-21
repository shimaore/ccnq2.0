#!/usr/bin/perl
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
use CCNQ::Install;
use CCNQ::XMPPAgent;

use Logger::Syslog;

use File::Spec;
use constant self_script => File::Spec->catfile(CCNQ::Install::install_script_dir,'xmpp_agent.pl');

# This start all the proper agents
# Note: this might not be the best (proper) way to do it, since some
#       agents may need to be running as specific userids (for e.g. opensips or freeswitch).

# Also: it's not certain that running all of these this way (using a single AnyEvent process)
#       might actually work.
sub run {
  resolve_roles_and_functions(sub{
    my ($cluster_name,$role,$function) = @_;
    my $running = 1;
    while($running) {
      info("(re)starting $function");
      eval {
        CCNQ::XMPPAgent::run($function);
      };
      $running = 0 if $@ eq CCNQ::Install::xmpp_restart_all;
    }
    warning(CCNQ::Install::xmpp_restart_all." received (in $function)");
    chdir(CCNQ::Install::install_script_dir);
    warning('exec '.self_script);
    exec(self_script,$function);
  });
}
run();
