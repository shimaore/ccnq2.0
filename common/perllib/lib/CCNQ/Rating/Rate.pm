package CCNQ::Rating::Rate;
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

use CCNQ::Rating::Bucket;
use CCNQ::Rating::Table;

use AnyEvent;
use CCNQ::AE;

our $cbef_guards;
our $cbef_actions;

sub cv_return {
  my $cv = AE::cv;
  $cv->send(@_);
  return $cv;
}

sub apply_cbef_guards {
  my ($cbef,@guards) = @_;

  # @guards is an array of guards; a guard is [ guard_name, guard_parameters ]
  # All guards must be true for the actions to be applied.

  my $rcv = AE::cv;

  # No guards to check
  if(!@guards) {
    $rcv->send(1);
    return $rcv;
  }

  # Obtain the code piece to run for this guard
  my @guard = @{shift @guards};
  my $guard_name = shift @guard;
  my $sub = $cbef_guards->{$guard_name};
  if(!$sub) {
    error("Unknown guard $guard_name");
    $rcv->send(0);
    return $rcv;
  }

  # Run the code piece
  $sub->($cbef,@guard)->cb(sub{
    my $result = CCNQ::AE::receive(@_);
    # If false, return false.
    if(!$result) {
      $rcv->send(0);
    # If true, recursively test the remaining guards.
    } else {
      apply_cbef_guards($cbef,@guards)->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
    }
  });

  return $rcv;
}

sub apply_cbef_actions {
  my ($cbef,@actions) = @_;

  # $actions is an arrayref of actions; an action is [ action_name, action_parameters ]

  my $rcv = AE::cv;

  if(!@actions) {
    $rcv->send(0);
    return $rcv;
  }

  my @action = @{shift @actions};
  my $action_name = shift @action;
  my $sub = $cbef_actions->{$action_name};
  if(!$sub) {
    error("Unknown action $action_name");
    $rcv->send(1);
    return $rcv;
  }

  $sub->($cbef,@action)->cb(sub{
    CCNQ::AE::receive(@_);
    apply_cbef_actions($cbef,@actions)->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
  });

  return $rcv;
}

=head1 rate_cbef($cbef,$plan) -> $cv

=cut

sub rate_cbef_step {
  my ($cbef,@rating_steps) = @_;

  my $rcv = AE::cv;

  if(!@rating_steps) {
    # Delete any component that could not be printed out.
    # (These are temporary anyway.)
    delete $cbef->{cost_bucket};
    delete $cbef->{duration_bucket};
    $rcv->send($cbef);
    return $rcv;
  }

  # Run through the guards/actions
  my $rating_step = shift @rating_steps;

  my $guards = $rating_step->guards || [];
  apply_cbef_guards($cbef,@$guards)->cb(sub{
    # If the guard returned true, execute the actions.
    my $result = CCNQ::AE::receive(@_);
    if($result) {
      my $actions = $rating_step->actions || [];
      # Actions may return 1 to indicate no further processing of steps.
      apply_cbef_actions($cbef,@$actions)->cb(sub{
        my $stop = CCNQ::AE::receive(@_);
        if($stop) {
          $rcv->send($cbef);
        } else {
          rate_cbef_step($cbef,@rating_steps)->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
        }
      });
    # If the guard returned false, skip the actions and attempt the next step.
    } else {
      rate_cbef_step($cbef,@rating_steps)->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
    }
  });

  return $rcv;
}


sub rate_cbef {
  my ($cbef,$plan) = @_;

  # ... do the preparation work (e.g. locate plan currency)
  $cbef->{currency} = $plan->currency;
  $cbef->{decimals} = $plan->decimals;

  return rate_cbef_step($cbef,$plan->rating_steps);
}

# In a pre-pay environment, to estimate the maximum duration;
# in any environment, to estimate the maximum rate per minute.
sub estimate_cbef {
  my ($cbef,$plan) = @_;

  my $rcv = AE::cv;

  $cbef->{count} ||= 1;
  $cbef->{duration} = undef;
  $cbef->{estimate} = 1;

  $cbef->{estimated_duration} = Math::BigInt->bzero;
  rate_cbef($cbef,$plan)->cb(sub{
    # Negative duration is a marker we use to indicate that the call
    # cannot be placed.
    if($cbef->estimated_duration < 0) {
      $rcv->send($cbef);
      return;
    };

    # Now deduct the jurisdiction taxes
    # We do this by adding all the tax rates...
    my $total_rates = 0;
    for my $tax (@{$cbef->tax || []}) {
      for my $jurisdiction (keys %{$tax}) {
        my $rate = $tax->{$jurisdiction};
        $total_rates += $rate/100.0;
      }
    }
    # ...then dividing the estimates appropriately
    $cbef->{estimated_duration} /= (1+$total_rates);
    $cbef->{estimated_rate}     *= (1+$total_rates); # per-minute
    $cbef->{estimated_cost}     *= (1+$total_rates); # per-operation

    $rcv->send($cbef);
  });

  return $rcv;
}



use Math::BigFloat;
use constant seconds_per_minute => Math::BigFloat->new(60);

=pod

  A Plan is the description of a function that takes a CBEF and translate
  it into a Rated CBEF, adding (at least) the following information:

    currency
    cost    (pre-tax) which might be divived into:
      duration_cost
      count_cost
    tax = { jurisdiction => percentage }

  The actual rating is done in CCNQ::Rating::Rate, which needs the following:

=cut


sub add_duration_rate_apply {
  my ($cbef,$rate) = @_;

  my $rcv = AE::cv;

  my $initial = $cbef->initial_duration;

  $cbef->{billable_duration} = $cbef->duration * $cbef->billable_count;

  my $billed_seconds = Math::BigInt->bzero;

  if($cbef->{billable_duration}) {
    $billed_seconds += $initial;
  }

  if($cbef->{billable_duration} > $initial) {
    my $increment = ($cbef->duration-$initial)/$cbef->increment_duration;
    my $seconds = $increment->bceil() * $cbef->increment_duration;
    $billed_seconds += $seconds;
  }

  my $cost;

  my $continuation_2 = sub {
    $cbef->{duration_cost} += $cost;
    $cbef->{cost}          += $cost;
    $rcv->send;
  };

  my $continuation_1 = sub {
    my $duration_cost = $billed_seconds * ($rate/seconds_per_minute);

    $cost = $cbef->rounding( $duration_cost );

    if($cbef->cost_bucket) {
      $cbef->cost_bucket->use($cbef,$cost)->cb(sub{
        $cost -= CCNQ::AE::receive(@_);
        $continuation_2->();
      });
    } else {
      $continuation_2->();
    }
  };

  if($cbef->duration_bucket) {
    $cbef->duration_bucket->use($cbef,$billed_seconds)->cb(sub{
      $billed_seconds -= CCNQ::AE::receive(@_);
      $continuation_1->();
    })
  } else {
    $continuation_1->();
  }

  return $rcv;
}

sub add_duration_rate_estimate {
  my ($cbef,$rate) = @_;

  my $rcv = AE::cv;

  if($cbef->estimated_duration < 0) {
    $rcv->send;
    return $rcv;
  }

  my $initial = $cbef->initial_duration;

  $cbef->{estimated_rate} = $rate if $rate > $cbef->{estimated_rate};

  my $remaining_duration = Math::BigInt->bzero;

  my $continuation_2 = sub {
    if($initial < $remaining_duration) {
      my $increment = ($remaining_duration-$initial)/$cbef->increment_duration;
      my $seconds = $increment->bceil() * $cbef->increment_duration;
      $cbef->{estimated_duration} = $initial + $seconds;
    }
    $rcv->send;
  };

  my $continuation_1 = sub {
    if($cbef->cost_bucket) {
      $cbef->cost_bucket->get_instance($cbef)->cb(sub{
        my $bucket_instance = CCNQ::AE::receive(@_);
        my $remaining_amount = 0;
        $remaining_amount = $bucket_instance->{value} if $bucket_instance;
        my $duration = $remaining_amount / ($rate/seconds_per_minute);
        $remaining_duration += $duration->bfloor();
        $continuation_2->();
      });
    } else {
      $continuation_2->();
    }
  };

  if($cbef->duration_bucket) {
    $cbef->duration_bucket->get_instance($cbef)->cb(sub{
      my $bucket_instance = CCNQ::AE::receive(@_);
      $remaining_duration += $bucket_instance->{value} if $bucket_instance;
      $continuation_1->();
    });
  } else {
    $continuation_1->();
  }

  return $rcv;
}

sub add_duration_rate {
  my ($cbef,$rate) = @_;
  $rate = Math::BigFloat->new($rate);

  if(!$cbef->estimate) {
    return add_duration_rate_apply($cbef,$rate);
  } else {
    return add_duration_rate_estimate($cbef,$rate);
  }
}

sub add_count_cost_apply {
  my ($cbef,$cost) = @_;

  my $rcv = AE::cv;

  my $continuation_1 = sub {
    $cbef->{count_cost}    += $cost;
    $cbef->{cost}          += $cost;
    $rcv->send;
  };

  if($cbef->cost_bucket) {
    $cbef->cost_bucket->use($cost)->cb(sub{
      $cost -= CCNQ::AE::receive(@_);
      $continuation_1->();
    });
  } else {
    $continuation_1->();
  }

  return $rcv;
}

sub add_count_cost_estimate {
  my ($cbef,$cost) = @_;

  my $rcv = AE::cv;

  my $continuation_1 = sub {
    # If we cannot afford it from the cost_bucket then we cannot place this call.
    if($cost > 0) {
      $cbef->{estimated_duration} = -1;
    }
    $rcv->send;
  };

  # Estimate
  $cbef->{estimated_cost} += $cost;
  if($cbef->cost_bucket) {
    $cbef->cost_bucket->get_value()->cb(sub{
      $cost -= CCNQ::AE::receive(@_);
      $continuation_1->();
    });
  } else {
    $continuation_1->();
  }

  return $rcv;
}

sub add_count_cost {
  my ($cbef,$amount) = @_;
  $amount = Math::BigFloat->new($amount);

  my $cost = $cbef->rounding( $amount * $cbef->billable_count );
  if(! $cbef->estimate) {
    return add_count_cost_apply($cbef,$cost);
  } else {
    return add_count_cost_estimate($cbef,$cost);
  }
}

sub add_jurisdiction {
  my ($cbef,$rec) = @_;
  push(@{$cbef->{tax}},$rec);
  cv_return;
}

=head1 CBEF Guards

=head2 event_type_is

Event type is [type]  (event_type == $1)

=head2 national_call

National calls        (to.country == from.country)

=head2 international_call

International calls   (to.country != from.country)

=head2 us_inter_state

US Inter-state        (to.country == us && from.country == us && to.state != from.state)

=head2 us_intra_state

US Intra-state        (to.country == us && from.country == us && to.state == from.state)

=head2 to_country

To [country]          (to.country == $1)

=head2 from_country

From [country]        (from.country == $1)

=head2 to_table

To [table]            (table->lookup(to.e164))

(The destination appears in the table.)

=head2 from_table

From [table]          (table->lookup(from.e164))

(The source appears in the table.)

=head2 zero_duration

Zero call duration

=head2 non_zero_duration

Non-zero call duration

=head2 shorter_than

Call duration < [value]

=head2 zero_count

Zero count

=head2 non_zero_count

Non-zero count

=cut

#  Rating periods -- in some cases, calls are rated differently based on time periods.
=pod UNIMPLEMENTED
    Day is [mon,tue,...]  (dow(start_date) == $1)
    Call started between time1 and time2
=cut


$cbef_guards = {

  event_type_is => sub {
    my ($cbef,$event_type) = @_;
    cv_return($cbef->event_type eq $event_type);
  },

  national_call => sub {
    my ($cbef) = @_;
    cv_return($cbef->to->country eq $cbef->from->country);
  },

  international_call => sub {
    my ($cbef) = @_;
    cv_return($cbef->to->country ne $cbef->from->country);
  },

  us_inter_state  => sub {
    my ($cbef) = @_;
    cv_return(
      $cbef->to->country eq 'us' &&
      $cbef->from->country eq 'us' &&
      $cbef->to->us_state ne $cbef->from->us_state
    );
  },

  us_intra_state  => sub {
    my ($cbef) = @_;
    cv_return(
      $cbef->to->country eq 'us' &&
      $cbef->from->country eq 'us' &&
      $cbef->to->us_state eq $cbef->from->us_state
    );
  },

  to_country => sub {
    my ($cbef,$country) = @_;
    cv_return($cbef->to->country eq $country);
  },

  from_country => sub {
    my ($cbef,$country) = @_;
    cv_return($cbef->from->country eq $country);
  },

  to_table => sub {
    my ($cbef,$table) = @_;
    return $table->lookup($cbef->to->e164);
  },

  from_table => sub {
    my ($cbef,$table) = @_;
    return $table->lookup($cbef->from->e164);
  },

  zero_duration => sub {
    my ($cbef) = @_;
    cv_return($cbef->estimate ? undef : $cbef->duration == 0);
  },

  non_zero_duration => sub {
    my ($cbef) = @_;
    cv_return($cbef->estimate ? 1 : $cbef->duration > 0);
  },

  shorter_than => sub {
    my ($cbef,$duration) = @_;
    cv_return($cbef->estimate ? undef : $cbef->duration < $duration);
  },

  zero_count => sub {
    my ($cbef) = @_;
    cv_return($cbef->estimate ? undef : $cbef->count == 0);
  },

  non_zero_count => sub {
    my ($cbef) = @_;
    cv_return($cbef->estimate ? 1 : $cbef->count > 0);
  },

};

=head1
Per-CBEF Actions

Note: these should probably appear in the order they are listed here.

=pod is_billable

Mard record as billable

=head2 is_non_billable

Mark record as non-billable

=head2 use_minutes_from_bucket

Use minutes from bucket: [bucket]

=head2 use_amount_from_bucket

Use amount from bucket: [bucket]

=head2 set_periods_values

Set initial period: [initial] with increment period [increment]

=head2 set_periods_table_to_e164

Use initial period and increment period from table: [table] using destination number

=head2 add_count_cost

Add count-based cost [amount]

=head2 add_count_cost_table_to_e164

Add count-based cost using [table] using destination number

=head2 add_duration_rate

Add duration-based rate [per-minute-rate]

=head2 add_duration_rate_table_to_e164

Add duration-based rating using [table] with rating key: {to.e164, ...}  [table must use same currency as plan]

=head2 add_jurisdiction

Add jurisdiction [jurisdiction] with rate [rate]

=head2 add_jurisdiction_table_to_e164

Add jurisdiction using [table] with key: {to.e164, ...}

=cut

$cbef_actions = {

  is_billable => sub {
    my ($cbef) = @_;
    $cbef->{billable_count} = $cbef->{count};
    cv_return;
  },

  is_non_billable => sub {
    my ($cbef) = @_;
    $cbef->{billable_count} = 0;
    cv_return;
  },

  use_minutes_from_bucket => sub {
    my ($cbef,$bucket_name) = @_;
    $cbef->{duration_bucket} = CCNQ::Rating::Bucket->new($bucket_name);
    # optionally
    $cbef->{duration_bucket}->use_account(0); # 0 = use account+sub_account
    return $cbef->{duration_bucket}->load;
  },

  use_amount_from_bucket => sub {
    my ($cbef,$bucket_name) = @_;
    $cbef->{cost_bucket} = CCNQ::Rating::Bucket->new($bucket_name);
    # optionally
    $cbef->{cost_bucket}->use_account(0); # 0 = use account+sub_account
    return $cbef->{duration_bucket}->load;
  },

  set_periods_values => sub {
    my ($cbef,$initial_duration,$increment_duration) = @_;
    $cbef->{initial_duration}   = $initial_duration;
    $cbef->{increment_duration} = $increment_duration;
    cv_return;
  },

  set_periods_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $rcv = AE::cv;
    $table->lookup($cbef->to->e164)->cb(sub{
      my $r = CCNQ::AE::receive(@_);
      if($r) {
        $cbef->{initial_duration}   = $r->{initial_duration};
        $cbef->{increment_duration} = $r->{increment_duration};
      }
      $rcv->send;
    });
    return $rcv;
  },

  add_count_cost => sub {
    my ($cbef,$amount) = @_;
    return add_count_cost($cbef,$amount);
  },

  add_count_cost_table_to_e164 => sub {
    my ($cbef,$table_name) = @_;
    my $rcv = AE::cv;
    CCNQ::Rating::Table->new($table_name)->lookup($cbef->to->e164)->cb(sub{
      my $r = CCNQ::AE::receive(@_);
      if($r) {
        add_count_cost($cbef,$r->{count_cost})->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
      } else {
        $rcv->send;
      }
    });
    return $rcv;
  },

  add_duration_rate => sub {
    my ($cbef,$rate) = @_;
    return add_duration_rate($cbef,$rate);
  },

  add_duration_rate_table_to_e164 => sub {
    my ($cbef,$table_name) = @_;
    my $rcv = AE::cv;
    CCNQ::Rating::Table->new($table_name)->lookup($cbef->to->e164)->cb(sub{
      my $r = CCNQ::AE::receive(@_);
      if($r) {
        add_duration_rate($cbef,$r->{duration_rate})->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
      } else {
        $rcv->send;
      }
    });
    return $rcv;
  },

  add_jurisdiction => sub {
    my ($cbef,$jurisdiction,$rate) = @_;
    return add_jurisdiction($cbef,{ $jurisdiction => $rate });
  },

  add_jurisdiction_table_to_e164 => sub {
    my ($cbef,$table_name) = @_;
    my $rcv = AE::cv;
    CCNQ::Rating::Table->new($table_name)->lookup($cbef->to->e164)->cb(sub{
      my $r = CCNQ::AE::receive(@_);
      if($r) {
        add_jurisdiction($cbef,{ $r->{jurisdiction} => $r->{rate} })->cb(sub{$rcv->send(CCNQ::AE::receive(@_))});
      } else {
        $rcv->send;
      }
    });
    return $rcv;
  },

};

1;
__END__

Possible TODOs:

Global Actions (applied at the sub-account or account level once all CBEFs have been processed)

Other objects:
  RatingTable: prefix-based values lookup (returns a record of values)
  Bucket: used to store away values
    * per account or sub-account
    * stored as durations (seconds) or amounts (currency)
    * with rollover, rollover maximum value or amount, rollover maximum duration / without rollover


Account or sub-account parameters:
  Discount
