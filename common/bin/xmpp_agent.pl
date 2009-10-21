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

sub run {
  my $running = 1;
  info('starting');
  while($running) {
    eval {
      CCNQ::XMPPAgent::run();
    };
    $running = 0 if $@ eq 'restart';
    info("restarting, running = $running");
  }
  chdir(CCNQ::Install::install_script_dir);
  warning('exec '.self_script);
  exec(self_script);
}
run();