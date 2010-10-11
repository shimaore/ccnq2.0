# CCNQ/Rating/Plan.pm
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


package CCNQ::Rating::Plan::RatingStep;
use strict; use warnings;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = shift;
  return bless $self, $class;
}

sub guards {
  # Returns a list of [ $guard_name, @guard_params ]
  my $self = shift;
  # returns a list of CCNQ::Rating::Plan::RatingStep instances.
  return $self->{guards};
}

sub actions {
  # Returns a list of [ $action_name, @action_params ]
  my $self = shift;
  return $self->{actions};
}


package CCNQ::Rating::Plan;
use strict; use warnings;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = shift;
  return bless $self, $class;
}

=pod

  $currency = currency()
    A plan is always indicated for a given currency.

=cut

sub currency {
  my $self = shift;
  # returns a unique currency name
  return $self->{currency};
}

=pod

  $decimals = decimals()
    How many decimals are needed in the currency.
    (This is used to compute per-item rounding.)

=cut

sub decimals {
  my $self = shift;
  # return a positive integer
  return $self->{decimals};
}

=pod
  @RatingSteps = rating_steps()
    The list of CCNQ::Rating::Rate operations that need to be performed
    to compute a Rated CBEF from a plain CBEF, for this plan.
=cut

sub rating_steps {
  my $self = shift;
  # returns a list of CCNQ::Rating::Plan::RatingStep instances.
  return map { CCNQ::Rating::Plan::RatingStep->new($_) } @{$self->{rating_steps}};
}

1;
