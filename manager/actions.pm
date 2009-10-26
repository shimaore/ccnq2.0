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

# manager/actions.pm

{
  install => sub {
    use AnyEvent::CouchDB;
    use CCNQ::Manager;
    info("Creating CouchDB database ".CCNQ::Manager::manager_db);
    my $db = couchdb(CCNQ::Manager::manager_db);
    $db->create()->send;
    return;
  },

  _session_ready => sub {
    my ($context) = @_;
    use CCNQ::XMPPAgent;
    debug("Manager _session_ready");
    CCNQ::XMPPAgent::join_cluster_room($context);
  },

  # Send requests out (message received e.g. from node/api/actions.pm)
  request => sub {
    use AnyEvent::CouchDB;
    use CCNQ::Manager;

    my ($request,$context) = @_;

    error("No request!"), return unless $request;

    debug("Manager handling request");

    my $db = couchdb(CCNQ::Manager::manager_db);

    # Log the request.
    my $cv = $db->save_doc($request);
    $cv->cb(sub{
      debug($_[0]->recv);

      debug("Saved request with ID=$request->{_id}.");
      # We use CouchDB's ID as the Request ID.
      $request->{request} = $request->{_id};

      # Now split the request into independent activities
      for my $activity (CCNQ::Manager::activities_for_request($request)) {
        debug("Creating new activity");
        $activity->{_parent} = $request->{request};
        my $cv2 = $db->save_doc($activity);
        $cv2->cb(sub{
          debug($_[0]->recv);

          debug("New activity ID=$activity->{_id} was created");

          # We use CouchDB's ID as the Activity ID.
          $activity->{activity} = $activity->{_id};

          # Submit the activity to the proper recipient.
          CCNQ::XMPPAgent::submit_activity($context,$activity);
          $db->save_doc($activity)->send;
          debug("Activity ID=$activity->{_id} was saved");
        });
        $cv2->send;
        debug("New activity ID=$activity->{_id} completed");
      };

      $db->save_doc($request)->send;
      debug("Request ID=$request->{_id} saved");
    });
    $cv->send;

    debug("Request completed");
    return;
  },

  # Response to requests
  _default => sub {
    use AnyEvent::CouchDB;
    use CCNQ::Manager;

    my ($action,$response) = @_;

    error("No action defined"), return unless $action;
    error("No activity defined for action $action"), return unless $response->{activity};

    debug("Trying to locate action=$action activity=$response->{activity}");
    return if $response->{activity} eq 'node/api'; # Not a real response.

    my $db = couchdb(CCNQ::Manager::manager_db);

    my $cv = $db->open_doc($response->{activity});
    $cv->cb(sub{
      my $activity = $_[0]->recv;
      debug("Found activity");
      if($activity) {
        $activity->{response} = $response->{params};
        warning("Activity $response->{activity} response action $response->{action} does not match requested action $activity->{action}")
          if $response->{action} ne $activity->{action};

        if($response->{error}) {
          warning("Activity $response->{activity} failed with error $response->{error}");
          $activity->{status} = 'error';
        } else {
          $activity->{status} = 'completed';
        }
        $db->save_doc($activity)->send;
      } else {
        error("Activity $response->{activity} does not exist!");
      }
    });
    $cv->send;
    return;
  },
}