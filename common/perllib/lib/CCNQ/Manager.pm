package CCNQ::Manager;
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
use CCNQ::Util;
use File::Spec;
use JSON;
use Logger::Syslog;

use constant manager_db => 'manager';
use constant::defer manager_requests_dir =>
  sub { File::Spec->catfile(CCNQ::Install::SRC,qw( manager requests )) };

=pod

  request_to_activity($request_type)
    If the request_type can be handled, returns a sub() to be used to handle the request.
    Otherwise return undef.

    Note: The sub() MUST return an array of activities (or an empty array).

=cut

sub request_to_activity {
  my ($request_type) = @_;

  use UNIVERSAL::require;
  my $request_module = "CCNQ::Manager::Requests::${request_type}";
  if($module->require) {
    return $module->can('run');
  } else {
    error("Request ${request_type} does not exist");
    return undef;
  }
}

=pod

  activities_for_request($request)
    Returns the list of activities to be completed to handle the request,
    if any.

=cut

sub activities_for_request {
  my ($request) = @_;
  my @result = ();
  if($request->{action}) {
    my $sub = request_to_activity($request->{action});
    if($sub) {
      return $sub->($request);
    } else {
      $request->{status} = 'Unknown request';
    }
  } else {
    $request->{status} = 'No action specified';
  }
  return ();
}

1;