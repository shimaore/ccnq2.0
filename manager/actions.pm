# manager/actions.pm

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

use AnyEvent::CouchDB;
use CCNQ::Manager;

use CCNQ::XMPPAgent;

{
  install => sub {
    my ($params,$context,$mcv) = @_;
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
    $mcv->send(CCNQ::Install::SUCCESS);
  },

  _session_ready => sub {
    my ($params,$context,$mcv) = @_;
    debug("Manager _session_ready");
    CCNQ::XMPPAgent::join_cluster_room($context);
    $mcv->send(CCNQ::Install::SUCCESS);
  },

=pod

  Request:

    Requests are generated with a unique identifier.

  Activity:
    Each request might contain one or more activities; activities are
    tried sequentially and are identified by their parent request ID
    followed by a sequential number.

  Responses:

    Responses received from hosts for each activity are stored individually
    and identified by the related activity's identifier, followed by the
    respondent's host name.

=cut

  # Send requests out (message received from node/api/actions.pm)
  _request => sub {
    my ($request,$context,$mcv) = @_;

    error("No request!"),
    return $mcv->send(CCNQ::Install::FAILURE("No request!"))
      unless $request and $request->{params};

    $request = $request->{params};

    debug("Manager handling request");

    my $db = couchdb(CCNQ::Manager::manager_db);

    # Log the request.
    my $cv = $db->save_doc($request);
    $request->{_id} = $request->{request} if $request->{request};

    $cv->cb( sub{ $_[0]->recv;
      $request->{request} ||= $request->{_id};
      debug("Saved request with ID=$request->{request}.");

      $db->save_doc($request)->cb(sub{ $_[0]->recv;
        # Now split the request into independent activities
        my @activities = CCNQ::Manager::activities_for_request($request);
        for my $rank (0..$#activities) {
          my $activity = $activities[$rank];

          debug("Creating new activity");
          $activity->{_id} = $request->{request}.'.'.$rank;
          $activity->{parent_request} = $request->{request};
          $activity->{rank} = $rank;
          $activity->{activity} = $activity->{_id};
          $activity->{next_activity} = $request->{request}.'.'.($rank+1)
            unless $rank == $#activities;

          $mcv->begin;
          $db->save_doc($activity)->cb(sub{ $_[0]->recv;

            debug("New activity ID=$activity->{activity} was created.");

            # Submit the activity to the proper recipient.
            # Should only be done for the first activity in the request.
            # The other ones will be processed when a positive response is received.
            if($rank == 0) {
              my $res = CCNQ::XMPPAgent::submit_activity($context,$activity);
              if($res->[0] eq 'ok') {
                debug("New activity ID=$activity->{activity} was submitted.");
              } else {
                error("Submission failed (in request): $res->[1] for activity ID=$activity->{activity}");
              }
            }

            $db->save_doc($activity)->cb(sub{$_[0]->recv;
              $mcv->end;
              debug("New activity ID=$activity->{activity} was saved.");
            });
          });
        }

        $mcv->send(CCNQ::Install::SUCCESS($request));
        debug("Request ID=$request->{request} submitted");
      });

    });

    $context->{condvar}->cb($cv);
  },

  # Response to requests
  _response => sub {
    my ($response,$context,$mcv) = @_;

    my $action = $response->{action};
    error("No action defined"), return unless $action;
    error("No activity defined for action $action"), return unless $response->{activity};

    debug("Trying to locate action=$action activity=$response->{activity}");
    return if $response->{activity} =~ qr{^node/api}; # Not a real response.

    my $db = couchdb(CCNQ::Manager::manager_db);

    my $cv = $db->open_doc($response->{activity});
    $cv->cb(sub{
      my $activity = $_[0]->recv;
      if($activity) {
        debug("Found activity");
        $activity->{response} = $response->{params};
        warning("Activity $response->{activity} response action $response->{action} does not match requested action $activity->{action}")
          if $response->{action} ne $activity->{action};

        $activity->{status} = $response->{status};

        my $actitivty_response = {%{$activity}};
        $activity_response->{_id} = $activity->{activity}.'.'.$activity->{from};
        $activity_response->{activity_response} = $activity_response->{_id};

        $db->save_doc($activity_response)->cb(sub{$_[0]->recv;
          debug("Activity response $activity_response->{_id} updated.");

          if($response->{error}) {
            info("Activity $response->{activity} failed with error $response->{error}, re-submitting");
            delete $activity->{status};
            delete $activity->{error};
            delete $activity->{from};
            my $res = CCNQ::XMPPAgent::submit_activity($context,$activity);
            if($res->[0] eq 'ok') {
              debug("Activity was re-submitted.");
            } else {
              error("Re-submission failed: $res->[1]");
            }
            $mcv->end;
          } else {
            # Process the next activity, if any.
            my $next_activity_id = $activity->{next_activity};
            if(!$next_activity_id) {
              $mcv->end;
              return;
            };
            debug("Locating next activity $next_activity_id");
            $db->open_doc($next_activity_id)->cb(sub{
              my $next_activity = $_[0]->recv;
              my $res = CCNQ::XMPPAgent::submit_activity($context,$next_activity);
              if($res->[0] eq 'ok') {
                debug("Next activity ID=$next_activity_id was submitted.");
              } else {
                error("Submission failed (in response): $res->[1] for activity ID=$next_activity_id");
              }
              $db->save_doc($next_activity)->cb(sub{$_[0]->recv;
                debug("Next activity ID=$next_activity_id submitted.");
                $mcv->end;
              });
            });
          }
        });
      } else {
        error("Activity $response->{activity} does not exist!");
        $mcv->end;
      }
    });
    $context->{condvar}->cb($cv);
  },

  # API "request status" query
  get_request_status => sub {
    my ($params,$context,$mcv) = @_;

    my $db = couchdb(CCNQ::Manager::manager_db);

    my $cv = $db->open_doc($params->{request_id});
    $cv->cb(sub{
      my $request = $_[0]->recv;
      if($request) {
        debug("Found request");

        $mcv->send(SUCCESS($request));
      } else {
        debug("Request $params->{request_id} not found.");
        $mcv->send(FAILURE("Request not found."));
      }
    });
    $context->{condvar}->cb($cv);
  },

}
