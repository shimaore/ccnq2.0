package CCNQ::Billing::Plan;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use AnyEvent;
use CCNQ::AE;

sub _plan_id {
  return join('/','plan',@_);
}

use CCNQ::Billing;
use CCNQ::Rating::Plan;

use Logger::Syslog;

=head1 retrieve_plan_by_name($plan_name)

Returns a condvar that will return either undef or a valid CCNQ::Rating::Plan object.

=cut

sub retrieve_plan_by_name {
  my ($plan_name) = @_;
  my $rcv = AE::cv;
  debug("CCNQ::Billing::Plan::retrieve_plan_by_name($plan_name) started");

  CCNQ::Billing::billing_retrieve({ _id => _plan_id($plan_name) })->cb(sub{
    my $rec = CCNQ::AE::receive(@_);
    $rcv->send($rec && CCNQ::Rating::Plan->new($rec));
  });
  return $rcv;
}

=head1 Content of a "plan" record

A plan record must contain:

  name: the name of the plan
  currency: the currency name for this plan
  decimals: the number of decimals used for rounding for this plan
  rating_steps: an array of { guards: [ guard* ], actions: [ action* ] } records
    Each guard item is of the format: [ $guard_name, @guard_params ]
    Each action item is of the format: [ $action_name, @action_params ]
    So rating_steps is of the format:
    [
      { guards: [ [ $guard_name, ...], [$guard_name, ...] ], 
        actions: [ [ $action_name, ...], [$action_name, ...] ],
      },
      { guards: [ [ $guard_name, ...], [$guard_name, ...] ], 
        actions: [ [ $action_name, ...], [$action_name, ...] ],
      },
      ...
    ]

=cut

sub update_plan {
  my ($params) = @_;
  return CCNQ::Billing::billing_update({
    %$params,
    profile => 'plan',
    _id => _plan_id($params->{name}),
  });
}

sub retrieve_plan {
  my ($params) = @_;
  return CCNQ::Billing::billing_retrieve({
    _id => _plan_id($params->{name})
  });
}

'CCNQ::Billing::Plan';
