package CCNQ::AE;
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
use AnyEvent::Util;
use CCNQ::Install; # For host_name

# Non-blocking version
sub execute {
  my $context = shift;
  my $command = join(' ',@_);

  my $cv = AnyEvent::Util::run_cmd([@_]);

  $cv->cb( sub {
    my $ret = shift->recv;
    return 1 if $ret == 0;
    # Happily lifted from perlfunc.
    if ($ret == -1) {
        error("Failed to execute ${command}: $!");
    }
    elsif ($ret & 127) {
        error(sprintf "Child command ${command} died with signal %d, %s coredump",
            ($ret & 127),  ($ret & 128) ? 'with' : 'without');
    }
    else {
        info(sprintf "Child command ${command} exited with value %d", $ret >> 8);
    }
    return 0;
  });

  $context->{condvar}->cb($cv);
}

use constant STATUS_COMPLETED => 'completed';
use constant STATUS_FAILED    => 'failed';

sub SUCCESS {
  my $result = shift;
  error(Carp::longmess("$result is not an hashref")) if $result && ref($result) ne 'HASH';
  return $result ? { status => STATUS_COMPLETED, result => $result, from => CCNQ::Install::host_name }
                 : { status => STATUS_COMPLETED,                    from => CCNQ::Install::host_name };
}

sub FAILURE {
  my $error = shift || 'No error specified';
  return { status => STATUS_FAILED, error => $error, from => CCNQ::Install::host_name };
}

use constant CANCEL => {};



1;
