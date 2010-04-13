package CCNQ::Actions::manager;
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

use CCNQ::Manager;
use CCNQ::XMPPAgent;
use CCNQ::CouchDB;
use AnyEvent;
use AnyEvent::CouchDB;
use Logger::Syslog;
use CCNQ::AE;

sub _install {
  return CCNQ::Manager::install(@_);
}

sub _session_ready {
  my ($params,$context) = @_;
  debug("Manager _session_ready");
  CCNQ::XMPPAgent::join_cluster_room($context);
  return;
}

# Send requests out (message received from node/api/actions.pm)
sub new_request {
  my ($request,$context) = @_;

  die ["No request!"]
    unless $request and $request->{params};

  $request = $request->{params};

  debug("Manager handling new request");

  my $db = couch(CCNQ::Manager::manager_uri)->db(CCNQ::Manager::manager_db);

  # Log the request.
  $request->{_id} = $request->{request} if $request->{request};

  my $rcv = AE::cv;

  my $cv = $db->save_doc($request);

  my $run_activities = sub {
    my @activities = $_[0]->recv;
    for my $activity_rank (0..$#activities) {
      my $activity = $activities[$activity_rank];

      debug("Creating new activity");
      $activity->{_id} = $request->{request}.'.'.$activity_rank;
      $activity->{parent_request} = $request->{request};
      $activity->{activity_rank} = $activity_rank;
      $activity->{activity} = $activity->{_id};
      $activity->{next_activity} = $request->{request}.'.'.($activity_rank+1)
        unless $activity_rank == $#activities;

      $rcv->begin;
      $db->save_doc($activity)->cb(sub{ $_[0]->recv;

        debug("New activity ID=$activity->{activity} was created.");

        # Submit the activity to the proper recipient.
        # Should only be done for the first activity in the request.
        # The other ones will be processed when a positive response is received.
        if($activity_rank == 0) {
          my $res = CCNQ::XMPPAgent::submit_activity($context,$activity);
          if($res->[0] eq 'ok') {
            debug("New activity ID=$activity->{activity} was submitted.");
          } else {
            error("Submission failed (in request): $res->[1] for activity ID=$activity->{activity}");
          }
        }

        $db->save_doc($activity)->cb(sub{$_[0]->recv;
          $rcv->end;
          debug("New activity ID=$activity->{activity} was saved.");
        });
      });
    } # for @activities

    debug("Request ID=$request->{request} submitted");
    # Send the Request ID back to the API.
    $rcv->send($request);
  };

  $cv->cb( sub{ $_[0]->recv;
    $request->{request} ||= $request->{_id};
    debug("Saving new request with ID=$request->{request}.");

    $db->save_doc($request)->cb(sub{ $_[0]->recv;
      # Now split the request into independent activities
      CCNQ::Manager::activities_for_request($request)->cb($run_activities);
    });

  });
  return $rcv;
}

# Response to requests
sub _response {
  my ($response,$context) = @_;

  my $action = $response->{action};
  error("No action defined"), return unless $action;
  error("No activity defined for action $action"), return unless $response->{activity};

  debug("Trying to locate action=$action activity=$response->{activity}");
  return if $response->{activity} =~ qr{^node/api}; # Not a real response.

  my $rcv = AE::cv;

  my $db = couch(CCNQ::Manager::manager_uri)->db(CCNQ::Manager::manager_db);

  my $cv = $db->open_doc($response->{activity});
  $cv->cb(sub{
    my $activity = $_[0]->recv;
    if($activity) {
      debug("Found activity");
      $activity->{response} = $response;
      warning("Activity $response->{activity} response action $response->{action} does not match requested action $activity->{action}")
        if $response->{action} ne $activity->{action};

      $activity->{status} = $response->{status};

      my $activity_response = {%{$activity}};
      $activity_response->{_id} = $activity->{activity}.'.'.$response->{from};
      $activity_response->{activity_responder} = $response->{from};

      $db->save_doc($activity_response)->cb(sub{$_[0]->recv;
        debug("Activity response $activity_response->{_id} updated.");

        if($response->{error}) {
          error("Activity $response->{activity} failed with error ".CCNQ::AE::pp($response->{error}).", re-submitting");
          delete $activity->{status};
          delete $activity->{error};
          delete $activity->{from};
          my $res = CCNQ::XMPPAgent::submit_activity($context,$activity);
          if($res->[0] eq 'ok') {
            debug("Activity was re-submitted.");
          } else {
            error("Re-submission failed: $res->[1]");
          }
          $rcv->send('cancel');
          return;
        } else {
          # Process the next activity, if any.
          my $next_activity_id = $activity->{next_activity};
          if(!$next_activity_id) {
            $rcv->send('cancel');
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
              $rcv->send('cancel');
              return;
            });
          });
        }
      });
    } else {
      error("Activity $response->{activity} does not exist!");
      $rcv->send('cancel');
      return;
    }
  });
  return $rcv;
}

# API "request status" query
sub get_request_status {
  my ($params,$context) = @_;
  return CCNQ::Manager::get_request_status($params->{request_id});
}

use CCNQ::Manager::CodeStore;

sub manager_update {
  my ($params,$context) = @_;
  return CCNQ::Manager::CodeStore::update($params);
}

sub manager_delete {
  my ($params,$context) = @_;
  return CCNQ::Manager::CodeStore::delete($params);
}

sub manager_retrieve {
  my ($params,$context) = @_;
  return CCNQ::Manager::CodeStore::retrieve($params);
}

sub manager_view {
  my ($params,$context) = @_;
  return CCNQ::Manager::CodeStore::view($params);
}

'CCNQ::Actions::manager';
