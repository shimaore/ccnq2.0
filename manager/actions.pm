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
    my ($params,$context) = @_;
    use AnyEvent::CouchDB;
    use CCNQ::Manager;
    my $db_name = CCNQ::Manager::manager_db;
    info("Creating CouchDB '${db_name}' database");
    my $couch = couch;
    my $db = $couch->db($db_name);
    my $cv = $db->create();
    $cv->cb(sub{
      info("Created CouchDB '${db_name}' database");
    });
    AnyEvent->idle(sub { $cv->recv });
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
    $context->{manager_request_handler} = $db->save_doc($request);

    $context->{manager_request_handler}->cb( sub{ $_[0]->recv;
      # We use CouchDB's ID as the Request ID.
      $request->{request} = $request->{_id};
      debug("Saved request with ID=$request->{request}.");

      $db->save_doc($request)->cb(sub{ $_[0]->recv;

        # Now split the request into independent activities
        for my $activity (CCNQ::Manager::activities_for_request($request)) {
          debug("Creating new activity");
          $activity->{_parent} = $request->{request};

          $db->save_doc($activity)->cb(sub{ $_[0]->recv;

            # We use CouchDB's ID as the Activity ID.
            $activity->{activity} = $activity->{_id};
            debug("New activity ID=$activity->{activity} was created");

            # Submit the activity to the proper recipient.
            CCNQ::XMPPAgent::submit_activity($context,$activity);
            debug("New activity ID=$activity->{activity} was submitted");

            $db->save_doc($activity)->cb(sub{$_[0]->recv});
          });
        }

        debug("Request ID=$request->{request} submitted");

      });

    });

    return;
  },

  # Response to requests
  _default => sub {
    use AnyEvent::CouchDB;
    use CCNQ::Manager;

    my ($action,$response,$context) = @_;

    error("No action defined"), return unless $action;
    error("No activity defined for action $action"), return unless $response->{activity};

    debug("Trying to locate action=$action activity=$response->{activity}");
    return if $response->{activity} eq 'node/api'; # Not a real response.

    my $db = couchdb(CCNQ::Manager::manager_db);

    $context->{response_handler} = $db->open_doc($response->{activity});
    $context->{response_handler}->cb(sub{
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
        $db->save_doc($activity)->cb(sub{$_[0]->recv;});
      } else {
        error("Activity $response->{activity} does not exist!");
      }
    });
    return;
  },
}