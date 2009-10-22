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

{
  # Send requests out
  request => sub {
    use AnyEvent::CouchDB;
    use CCNQ::Manager;

    my ($request,$context) = @_;

    my $db = couchdb(CCNQ::Manager::manager_db);

    # Log the request.
    $db->save_doc($request)->recv;

    # We use CouchDB's ID as the Request ID.
    $request->{request} = $request->{_id};

    # Now split the request into independent activities
    for my $activity (CCNQ::Manager::activities_for_request($request)) {
      $activity->{_parent} = $request->{request};
      $db->save_doc($activity)->recv;

      # We use CouchDB's ID as the Activity ID.
      $activity->{activity} = $activity->{_id};

      # Submit the activity to the proper recipient.
      CCNQ::Manager::submit_activity($context,$activity);
      $db->save_doc($activity)->recv;
    }

    $db->save_doc($request)->recv;
    return;
  },

  # Response to requests
  _default => sub {
    my ($action,$response) = @_;

    my $db = couchdb(CCNQ::Manager::manager_db);

    my $activity = $db->open_doc($response->{activity})->recv;
    if($activity) {
      $activity->{response} = $response->{params};
      warning("Activity $response->{activity} response action $response->{action} does not match requested action $activity->{action}")
        if $response->{action} ne $activity->{action};

      if($response->{error}) {
        warning("Activity $response->{activity} failed with error $response->{error}")
        $activity->{status} = 'error';
      } else {
        $activity->{status} = 'completed';
      }
      $db->save_doc($activity)->recv;
    } else {
      error("Activity $response->{activity} does not exist!");
    }
    return { _no_response => 1 };
  },
}