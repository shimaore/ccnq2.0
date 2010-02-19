package CCNQ::AE::Run;
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

use Carp;
use CCNQ::Install;
use CCNQ::Util;
use CCNQ::AE;

use constant actions_file_name => 'actions.pm';
sub actions_file {
  my ($function) = @_;
  return File::Spec->catfile(CCNQ::Install::SRC,$function,actions_file_name);
}

=pod

  attempt_run locates an "actions.pm" module and returns a sub() that
  will execute an action in it.
  "actions.pm" modules must return a hashred, which keys are the action
  names, and the values are sub()s.

  The sub($cv) returned by attempt_run expects one argument, an AnyEvent
  condvar, which will be sent the result, in the form:

  { status => 'completed', params => $results }
  { status => 'failed', error => $error_msg }

  Note: failure is detected by the presence of the "error" field,
        not by the fact that status is "failed".

=cut

sub attempt_run {
  my ($function,$action,$params,$context) = @_;

  debug(qq(attempt_run($function,$action): started));
  my $run_file = actions_file($function);

  # Errors which lead to not being able to submit the request are not reported.
  my $cancel = sub { debug("attempt_run($function,$action): cancel"); shift->send(CCNQ::AE::CANCEL); };

  # No "actions.pm" for the selected function.
  warning(qq(attempt_run($function,$action): No such file "${run_file}", skipping)),
  return $cancel unless -e $run_file;

  # An error occurred while reading the file.
  my $eval = CCNQ::Util::content_of($run_file);
  return $cancel if !defined($eval);

  # An error occurred while parsing the file.
  my $run = eval($eval);
  warning(qq(attempt_run($function,$action): Executing "${run_file}" returned: $@)),
  return $cancel if $@;

  return sub {
    my $cv = shift;
    debug("start of attempt_run($function,$action)->($cv)");

    my $result = undef;
    eval {
      if($run->{$action}) {
        $run->{$action}->($params,$context,$cv);
      } elsif($run->{_dispatch}) {
        $run->{_dispatch}->($action,$params,$context,$cv);
      } else {
        debug("attempt_run($function,$action): No action available");
        $cancel->($cv);
      }
      return;
    };

    if($@) {
      my $error_msg = "attempt_run($function,$action): failed with error $@";
      debug($error_msg);
      $cv->send(CCNQ::AE::FAILURE($error_msg));
    }
    debug("end of attempt_run($function,$action)->($cv)");
  };
}

sub attempt_run_module {
  my ($function,$action,$params,$context) = @_;

  use UNIVERSAL::require;
  debug(qq(attempt_run($function,$action): started));
  my $module = "CCNQ::Actions::${function}";

  # Errors which lead to not being able to submit the request are not reported.
  my $cancel = sub { debug("attempt_run($function,$action): cancel"); shift->send(CCNQ::AE::CANCEL); };

  warning(qq(attempt_run($function,$action): Invalid module "${module}", skipping)),
  return $cancel unless $module->require;

  return sub {
    my $cv = shift;
    debug("start of attempt_run($function,$action)->($cv)");

    my $result = undef;
    eval {
      if($module->can($action)) {
        # Will call AUTOLOAD automatically
        $module->{$action}->($params,$context,$cv);
      } else {
        debug("attempt_run($function,$action): No action available");
        $cancel->($cv);
      }
      return;
    };

    if($@) {
      my $error_msg = "attempt_run($function,$action): failed with error $@";
      debug($error_msg);
      $cv->send(CCNQ::AE::FAILURE($error_msg));
    }
    debug("end of attempt_run($function,$action)->($cv)");
  };
}

sub attempt_on_roles_and_functions {
  my ($action,$params,$context,$mcv) = @_;
  $params ||= {};

  CCNQ::Install::resolve_roles_and_functions(sub {
    my ($cluster_name,$role,$function) = @_;
    my $fun = attempt_run($function,$action,{ %{$params}, cluster_name => $cluster_name, role => $role },$context);

    my $cv = AnyEvent->condvar;
    $fun->($cv);

    info("Waiting for Function: $function Action: $action Cluster: $cluster_name to complete");
    eval { $cv->recv };
    if($@) {
      error("Function: $function Action: $action Cluster: $cluster_name Failure: $@");
    } else {
      info("Function: $function Action: $action Cluster: $cluster_name Completed");
    }
  });
  $mcv->send;
}

1;
