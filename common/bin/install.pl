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

# Note: install.pl is started from the proper directory, so locating
# CCNQ::Install is not an issue.

use CCNQ::Install;

sub run {
  # Update the code from the Git repository.
  chdir(CCNQ::Install::SRC) or die "chdir(".CCNQ::Install::SRC."): $!";
  CCNQ::Install::_execute(qw( git pull ));

  CCNQ::Install::attempt_on_roles_and_functions('install');
  print "Done.\n";
}

run();
