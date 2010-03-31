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

use constant::defer manager_uri => sub {
  CCNQ::Install::couchdb_local_uri;
};
use constant manager_db => 'manager';

use constant js_report_requests => <<'JAVASCRIPT';
  function(doc) {
    if(doc.parent_request && doc.activity_responder) {
      emit([doc.parent_request,doc.activity_rank,doc.activity_responder],null);
      return;
    }
    if(doc.parent_request) {
      emit([doc.parent_request,doc.activity_rank],null);
      return;
    }
    if(doc.request) {
      emit([doc.request],null);
    }
  }
JAVASCRIPT

use constant manager_designs => {
  report => {
    language => 'javascript',
    views    => {
      requests => {
        map => js_report_requests,
        # no reduce function
      },
      # Other views for _design/report here
    },
  },
  # Other designs here
};

sub install {
  return CCNQ::CouchDB::install(manager_uri,manager_db,manager_designs);
}

sub get_request_status {
  my ($request_id) = @_;
  return CCNQ::CouchDB::view_cv(manager_uri,manager_db,{
    view => 'report/requests',
    _id  => [$request_id],
  });
}

use constant::defer manager_requests_dir =>
  sub { File::Spec->catfile(CCNQ::Install::SRC,qw( manager requests )) };

=pod

  request_to_activity($request_type)
    Returns a condvar.

    If the request_type can be handled, the condvar returns a sub() to be used to handle the request.
    Otherwise the condvar returns undef.

    Note: The sub() will return an array of activities (or an empty array).

=cut

sub request_to_activity {
  my ($request_type) = @_;

  my $cv = AE::cv;

  use UNIVERSAL::require;
  my $module = "CCNQ::Manager::Requests::${request_type}";
  if($module->require) {
    $cv->send($module->can('run'));
    return $cv;
  }

  use CCNQ::CouchDB::CodeStore;
  my $store = CCNQ::CouchDB::CodeStore->new(manager_uri,manager_db);
  $store->load_entry->cb($cv);

  return $cv;
}

=pod

  activities_for_request($request)
    Returns the list of activities to be completed to handle the request,
    if any.

=cut

sub activities_for_request {
  my ($request) = @_;

  my $cv = AE::cv;

  if(!$request->{action}) {
    $request->{status} = STATUS_FAILED;
    $request->{error} = 'No action specified';
    $cv->send;
    return;
  }

  request_to_activity($request->{action})->cb(sub{
    my $sub = shift->recv;

    if(!$sub) {
      $request->{status} = STATUS_FAILED;
      $request->{error} = 'Unknown request';
      $cv->send;
      return;
    }

    if(ref($sub) ne 'CODE') {
      $request->{status} = STATUS_FAILED;
      $request->{error} = $sub; # should be an ARRAY describing the error.
      $cv->send;
      return;
    }

    my @activities = eval { $sub->($request) };
    if($@) {
      $request->{status} = STATUS_FAILED;
      $request->{error} = ['Request generation failed: [_1]',$@];
      $cv->send;
      return;
    }

    $cv->send(@activities);
  });

  return $cv;
}

1;
