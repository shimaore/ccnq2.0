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
    my ($params,$context,$mcv) = @_;
    use AnyEvent::CouchDB;
    use CCNQ::Manager;
    my $db_name = CCNQ::Manager::manager_db;
    info("Creating CouchDB '${db_name}' database");
    my $couch = couch;
    my $db = $couch->db($db_name);
    $mcv->begin;
    my $cv = $db->create();
    $cv->cb(sub{
      info("Created CouchDB '${db_name}' database");
      $mcv->end;
    });
    $context->{condvar}->cb($cv);
    return;
  },

  _session_ready => sub {
    my ($params,$context) = @_;
    use CCNQ::XMPPAgent;
    debug("Manager _session_ready");
    CCNQ::XMPPAgent::join_cluster_room($context);
    return;
  },

  # Send requests out (message received from node/api/actions.pm)
  _request => sub {
    use AnyEvent::CouchDB;
    use CCNQ::Manager;

    my ($request,$context,$mcv) = @_;

    error("No request!"), return unless $request and $request->{params};
    $request = $request->{params};

    debug("Manager handling request");

    my $db = couchdb(CCNQ::Manager::manager_db);

    # XXX Use the original's Activity's ID (+random) as the new Request ID
    # XXX Use the Request ID + sequential number as the Activity ID.

    $mcv->begin;

    # Log the request.
    my $cv = $db->save_doc($request);

    $cv->cb( sub{ $_[0]->recv;
      # We use CouchDB's ID as the Request ID.
      $request->{request} = $request->{_id};
      debug("Saved request with ID=$request->{request}.");

      $db->save_doc($request)->cb(sub{ $_[0]->recv;
        # Now split the request into independent activities
        for my $activity (CCNQ::Manager::activities_for_request($request)) {
          debug("Creating new activity");
          $activity->{activity_parent} = $request->{request};

          $mcv->begin;
          $db->save_doc($activity)->cb(sub{ $_[0]->recv;

            # We use CouchDB's ID as the Activity ID.
            $activity->{activity} = $activity->{_id};
            debug("New activity ID=$activity->{activity} was created.");

            # Submit the activity to the proper recipient.
            my $res = CCNQ::XMPPAgent::submit_activity($context,$activity);
            if($res->[0] eq 'ok') {
              debug("New activity ID=$activity->{activity} was submitted.");

              $db->save_doc($activity)->cb(sub{$_[0]->recv;
                $mcv->end;
                debug("New activity ID=$activity->{activity} was saved.");
              });
            } else {
              error("Submission failed: $res->[1] for activity ID=$activity->{activity}");
            }
          });
        }

        $mcv->end;
        debug("Request ID=$request->{request} submitted");

      });

    });

    $context->{condvar}->cb($cv);
    return;
  },

  # Response to requests
  _response => sub {
    use AnyEvent::CouchDB;
    use CCNQ::Manager;

    my ($response,$context,$mcv) = @_;

    my $action = $response->{action};
    error("No action defined"), return unless $action;
    error("No activity defined for action $action"), return unless $response->{activity};

    debug("Trying to locate action=$action activity=$response->{activity}");
    return if $response->{activity} =~ qr{^node/api}; # Not a real response.

    my $db = couchdb(CCNQ::Manager::manager_db);

    $mcv->begin;

    my $cv = $db->open_doc($response->{activity});
    $cv->cb(sub{
      my $activity = $_[0]->recv;
      if($activity) {
        debug("Found activity");
        $activity->{response} = $response->{params};
        warning("Activity $response->{activity} response action $response->{action} does not match requested action $activity->{action}")
          if $response->{action} ne $activity->{action};

        $activity->{status} = $response->{status};
        if($response->{error}) {
          warning("Activity $response->{activity} failed with error $response->{error}");
        }
        $db->save_doc($activity)->cb(sub{$_[0]->recv;
          $mcv->end;
          debug("Activity $response->{activity} updated.")
        });
      } else {
        error("Activity $response->{activity} does not exist!");
      }
    });
    $context->{condvar}->cb($cv);
    return;
  },
}