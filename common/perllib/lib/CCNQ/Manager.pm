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
use File::Spec;
use JSON;
use Logger::Syslog;
use Memoize;

use constant manager_db => 'manager';
memoize('manager_requests_dir');
sub manager_requests_dir { File::Spec->catfile(CCNQ::Install::SRC,qw( manager requests )); }

=pod

  request_to_activity($request_type)
    If the request_type can be handled, returns a sub() to be used to handle the request.
    Otherwise return undef.

    Note: The sub() MUST return an array of activities (or an empty array).

=cut

sub request_to_activity {
  my ($request_type) = @_;

  # Try to find a file in manager/requests to handle the request.
  my $request_file = File::Spec->catfile(manager_requests_dir,"${request_type}.pm");
  if( -e $request_file ) {
    my $eval = CCNQ::Install::content_of($request_file);
    return undef if !defined($eval);
    my $sub = eval($eval);
    if($@) {
      error("Request ${request_type} code is invalid: $@");
      return undef;
    }
    return $sub;
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