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
use AnyEvent;
use CCNQ::Install;

=head2 attempt_run($function,$action,$params,$context)

Return undef if the function/action combination does not exist.

If the params-set is a response, call that functions' "_response" action,
if it exists.

Otherwise attempt to locate the action inside the function, and use
the "_dispatch" action (if available) if no specific action is defined.

Returns a sub{} that will return an AE::cv which when called will return
the value for the function/action combination. (The sub{} might fail with
die(). If die('cancel') is used it means the action should not be replied to.)

Note: failure is detected by the presence of the "error" field,
      not by the fact that status is "failed".

=cut

sub attempt_run {
  my ($function,$action,$params,$context) = @_;

  use UNIVERSAL::require;
  debug(qq(attempt_run($function,$action): started));
  my $module = "CCNQ::Actions::${function}";
  $module =~ s{/}{::}g;

  # Errors which lead to not being able to submit the request are not reported.
  warning(qq(attempt_run($function,$action): Invalid module "${module}", skipping)),
  return unless $module->require;

  # This is a response.
  if($params->{status}) {
    if($module->can('_response')) {
      return sub {
        my $cv = $module->can('_response')->($params,$context);
        return if !$cv;
        # If the _response needs post-processing we still need to make sure it gets canceled.
        my $rcv = AE::cv;
        $cv->cb(sub{
          eval { shift->recv };
          # Do not report errors upstream, but still log them.
          error("Response failed with error: $@") if $@;
          $rcv->send('cancel');
        });
        return $rcv;
      };
    }
    return;
  }

  # This is a request.
  if($module->can($action)) {
    return sub { $module->can($action)->($params,$context) };
  } elsif($module->can('_dispatch')) { # Eventually replace with AUTOLOAD
    return sub { $module->can('_dispatch')->($action,$params,$context) };
  }
  return;
}

sub attempt_on_roles_and_functions {
  my ($action,$params,$context) = @_;
  $params ||= {};

  my $rcv = AE::cv;
  CCNQ::Install::resolve_roles_and_functions(sub {
    my ($cluster_name,$role,$function) = @_;

    my $fun = attempt_run($function,$action,{ %{$params}, cluster_name => $cluster_name, role => $role },$context);
    return unless $fun;

    $rcv->begin;

    my $cv = eval { $fun->() };
    if($@) {
      error("Function: $function Action: $action Cluster: $cluster_name Failure: $@");
      $rcv->send;
    }

    # Assume success if no condvar is returned.
    # (This is the normal case for "_install".)
    debug("Function: $function Action: $action Cluster: $cluster_name has already Completed"),
    return $rcv->end if !$cv;

    debug("Waiting for Function: $function Action: $action Cluster: $cluster_name to complete");
    eval { $cv->recv };
    if($@) {
      error("Function: $function Action: $action Cluster: $cluster_name Failure: $@");
      $rcv->send;
    }

    debug("Function: $function Action: $action Cluster: $cluster_name Completed");
    $rcv->end;
  });
  return $rcv;
}

1;
