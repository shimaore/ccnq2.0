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

# XXX Build modules?


sub apply_cbef_guards {
  my ($cbef,$guards) = @_;
  # $guards is an arrayref of guards; a guard is [ guard_name, guard_parameters ]
  # All guards must be true for the actions to be applied.
  # Note: if tables are found, they MUST be Rating::Table instances, not the table names.
  for my $guard (@{$guards}) {
    my @guard = @{$guard};
    my $sub = cbef_guards->{shift @guard};
    error("Unknown condition $guard"), return 0 unless $sub;
    return 0 if !$sub->($cbef,@guard);
  }
  return 1;
}

sub apply_cbef_actions {
  my ($cbef,$actions) = @_;
  # $actions is an arrayref of actions; an action is [ action_name, action_parameters ]
  # Note: if tables are found, they MUST be Rating::Table instances, not the table names.
  for my $action (@{$actions}) {
    my @action = @{$action};
    my $sub = cbef_actions->{shift @action};
    error("Unknown action $guard"), return 1 unless $sub;
    $sub->($cbef,@guard);
  }
  return 0;
}

sub rate_cbef {
  my ($cbef,$plan) = @_;
  # ... do the preparation work (e.g. locate plan currency)
  $cbef->{currency} = $plan->currency;
  $cbef->{decimals} = $plan->decimals;

  # Run through the guards/actions
  for my $rating_step ($plan->rating_steps) {
    my $guards = $rating_step->guards;
    next if $guards && !apply_cbef_guards($cbef,$guards);
    my $actions = $rating_step->actions;
    last if apply_cbef_actions($cbef,$actions);
  }

  # Delete any component that could not be printed out.
  # (These are temporary anyway.)
  delete $cbef->{cost_bucket};
  delete $cbef->{duration_bucket};
}

# In a pre-pay environment, to estimate the maximum duration;
# in any environment, to estimate the maximum rate per minute.
sub estimate_cbef {
  my ($cbef,$plan) = @_;
  $cbef->{count} ||= 1;
  $cbef->{duration} = undef;
  $cbef->{estimate} = 1;

  $cbef->{estimated_duration} = Math::BigInt->bzero;
  rate_cbef($cbef,$plan);

  # Negative duration is a marker we use to indicate that the call
  # cannot be placed.
  return $cbef if $cbef->estimated_duration < 0;

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
  return $cbef;
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

  my $initial = $cbef->initial_duration;

  $cbef->{billable_duration} = $cbef->duration * $cbef->billable_count;

  my $billed_seconds = Math::BigInt->bzero;

  if($cbef->{billable_duration}) {
    $billed_seconds += $initial;
  }

  if($cbef->{billable_duration} > $initial) {
    my $increments = ($cbef->duration-$initial)/$cbef->increment_duration;
    my $seconds = $increment->bceil() * $cbef->increment_duration;
    $billed_seconds += $seconds;
  }

  if($cbef->duration_bucket) {
    $billed_seconds -= $cbef->duration_bucket->use($cbef,$billed_seconds);
  }

  my $duration_cost = $billed_seconds * ($rate/seconds_per_minute);

  my $cost = $cbef->rounding( $duration_cost );
  $cost -= $cbef->cost_bucket->use($cost) if $cbef->cost_bucket;
  $cbef->{duration_cost} += $cost;
  $cbef->{cost}          += $cost;
}

sub add_duration_rate_estimate {
  my ($cbef,$rate) = @_;

  return if $cbef->estimated_duration < 0;

  my $initial = $cbef->initial_duration;

  $cbef->{estimated_rate} = $rate if $rate > $cbef->{estimated_rate};

  my $remaining_duration = Math::BigInt->bzero;
  if($cbef->duration_bucket) {
    $remaining_duration += $cbef->duration_bucket->get_value($cbef);
  }

  if($cbef->cost_bucket) {
    my $remaining_amount = $cbef->cost_bucket->get_value($cbef);
    my $duration = $remaining_amount / ($rate/seconds_per_minute);
    $remaining_duration += $duration->bfloor();
  }

  if($initial < $remaining_duration) {
    my $increments = ($remaing_duration-$initial)/$cbef->increment_duration;
    my $seconds = $increment->bceil() * $cbef->increment_duration;
    $cbef->{estimated_duration} = $initial + $seconds;
  }
}

sub add_duration_rate {
  my ($cbef,$rate) = @_;
  $rate = Math::BigFloat->new($rate);

  if(!$cbef->estimate) {
    add_duration_rate_apply($cbef,$rate);
  } else {
    add_duration_rate_estimate($cbef,$rate);
  }
}

sub add_count_cost_apply {
  my ($cbef,$cost) = @_;

  $cost -= $cbef->cost_bucket->use($cost) if $cbef->cost_bucket;
  $cbef->{count_cost}    += $cost;
  $cbef->{cost}          += $cost;
}

sub add_count_cost_estimate {
  my ($cbef,$cost) = @_;

  # Estimate
  $cbef->{estimated_cost} += $cost;
  $cost -= $cbef->cost_bucket->get_value() if $cbef->cost_bucket;
  # If we cannot afford it from the cost_bucket then we cannot place this call.
  if($cost > 0) {
    $cbef->{estimated_duration} = -1;
  }
}

sub add_count_cost {
  my ($cbef,$amount) = @_;
  $amount = Math::BigFloat->new($amount);

  my $cost = $cbef->rounding( $amount * $cbef->billable_count );
  if(! $cbef->estimate) {
    add_count_cost_apply($cbef,$cost);
  } else {
    add_count_cost_estimate($cbef,$cost);
  }
}

sub add_jurisdiction {
  my ($cbef,$rec) = @_;
  push(@{$cbef->{tax}},$rec);
}

=head1 CBEF Guards
=cut

use constant cbef_guards => {

=head2 event_type_is

Event type is [type]  (event_type == $1)

=cut

  event_type_is => sub {
    my ($cbef,$event_type) = @_;
    return $cbef->event_type eq $event_type;
  },

=head2 national_call

National calls        (to.country == from.country)

=cut
  national_call => sub {
    my ($cbef) = @_;
    return $cbef->to->country eq $cbef->from->country;
  },

=head2 international_call

International calls   (to.country != from.country)

=cut
  international_call => sub {
    my ($cbef) = @_;
    return $cbef->to->country ne $cbef->from->country;
  },

=head2 us_inter_state

US Inter-state        (to.country == us && from.country == us && to.state != from.state)

=cut
  us_inter_state  => sub {
    my ($cbef) = @_;
    return $cbef->to->country eq 'us' && $cbef->from->country eq 'us' && $cbef->to->us_state ne $cbef->from->us_state;
  },

=head2 us_intra_state

US Intra-state        (to.country == us && from.country == us && to.state == from.state)

=cut
  us_intra_state  => sub {
    my ($cbef) = @_;
    return $cbef->to->country eq 'us' && $cbef->from->country eq 'us' && $cbef->to->us_state eq $cbef->from->us_state;
  },

=head2 to_country

To [country]          (to.country == $1)

=cut
  to_country => sub {
    my ($cbef,$country) = @_;
    return $cbef->to->country eq $country;
  },

=head2 from_country

From [country]        (from.country == $1)

=cut
  from_country => sub {
    my ($cbef,$country) = @_;
    return $cbef->from->country eq $country;
  },

=head2 to_table

To [table]            (table->lookup(to.e164))

(The destination appears in the table.)

=cut
  to_table => sub {
    my ($cbef,$table) = @_;
    return $table->lookup($cbef->to->e164}) ? 1 : 0;
  },

=head2 from_table

From [table]          (table->lookup(from.e164))

(The source appears in the table.)

=cut
  from_table => sub {
    my ($cbef,$table) = @_;
    return $table->lookup($cbef->from->e164) ? 1 : 0;
  },

=head2 zero_duration

Zero call duration

=cut
  zero_duration => sub {
    my ($cbef) = @_;
    return undef if $cbef->estimate;
    return $cbef->duration == 0;
  },

=head2 non_zero_duration

Non-zero call duration

=cut
  non_zero_duration => sub {
    my ($cbef) = @_;
    return 1 if $cbef->estimate;
    return $cbef->duration > 0;
  },

=head2 shorter_than

Call duration < [value]

=cut
  shorter_than => sub {
    my ($cbef,$duration) = @_;
    return undef if $cbef->estimate;
    return $cbef->duration < $duration;
  },

=head2 zero_count

Zero count

=cut
  zero_count => sub {
    my ($cbef) = @_;
    return undef if $cbef->estimate;
    return $cbef->count == 0;
  },

=head2 non_zero_count

Non-zero count

=cut
  non_zero_count => sub {
    my ($cbef) = @_;
    return 1 if $cbef->estimate;
    return $cbef->count > 0;
  },

#  Rating periods -- in some cases, calls are rated differently based on time periods.
=pod
    Day is [mon,tue,...]  (dow(start_date) == $1)
    Call started between time1 and time2
=cut

};

=head1
Per-CBEF Actions

Note: these should probably appear in the order they are listed here.

=cut

use constant cbef_actions => {

=pod is_billable

Mard record as billable

=cut
  is_billable => sub {
    my ($cbef) = @_;
    $cbef->{billable_count} = $cbef->{count};
  },

=head2 is_non_billable

Mark record as non-billable

=cut
  is_non_billable => sub {
    my ($cbef) = @_;
    $cbef->{billable_count} = 0;
  },

=head2 use_minutes_from_bucket

Use minutes from bucket: [bucket]

=cut
  use_minutes_from_bucket => sub {
    my ($cbef,$bucket) = @_;
    $cbef->{duration_bucket} = $bucket;
  },

=head2 use_amount_from_bucket

Use amount from bucket: [bucket]

=cut
  use_amount_from_bucket => sub {
    my ($cbef,$bucket) = @_;
    $cbef->{cost_bucket} = $bucket;
  },



=head2 set_periods_values

Set initial period: [initial] with increment period [increment]

=cut
  set_periods_values => sub {
    my ($cbef,$initial_duration,$increment_duration) = @_;
    $cbef->{initial_duration}   = $initial_duration;
    $cbef->{increment_duration} = $increment_duration;
  },

=head2 set_periods_table_to_e164

Use initial period and increment period from table: [table] using destination number

=cut
  set_periods_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $r = $table->lookup($cbef->to->e164);
    if($r) {
      $cbef->{initial_duration}   = $r->{initial_duration};
      $cbef->{increment_duration} = $r->{increment_duration};
    }
  },

=head2 add_count_cost

Add count-based cost [amount]

=cut
  add_count_cost => sub {
    my ($cbef,$amount) = @_;
    add_count_cost($cbef,$amount);
  },

=head2 add_count_cost_table_to_e164

Add count-based cost using [table] using destination number

=cut
  add_count_cost_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $r = $table->lookup($cbef->to->e164);
    if($r) {
      add_count_cost($cbef,$r->{count_cost});
    }
  },

=head2 add_duration_rate

Add duration-based rate [per-minute-rate]

=cut
  add_duration_rate => sub {
    my ($cbef,$rate) = @_;
    add_duration_rate($cbef,$rate);
  },

=head2 add_duration_rate_table_to_e164

Add duration-based rating using [table] with rating key: {to.e164, ...}  [table must use same currency as plan]

=cut
  add_duration_rate_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $r = $table->lookup($cbef->to->e164);
    if($r) {
      add_duration_rate($cbef,$r->{duration_rate});
    }
  },


=head2 add_jurisdiction

Add jurisdiction [jurisdiction] with rate [rate]

=cut
  add_jurisdiction => sub {
    my ($cbef,$jurisdiction,$rate) = @_;
    add_jurisdiction($cbef,{ $jurisdiction => $rate });
  }

=head2 add_jurisdiction_table_to_e164

Add jurisdiction using [table] with key: {to.e164, ...}

=cut
  add_jurisdiction_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $r = $table->lookup($cbef->to->e164);
    if($r) {
      add_jurisdiction($cbef,{ $jurisdiction => $rate });
    }
  },

}

1;
__END__

Add duration to counter: [counter]
Add billable duration to counter: [counter]
Add



Global Actions (applied at the sub-account or account level once all CBEFs have been processed)



Other objects:
  RatingTable: prefix-based values lookup (returns a record of values)
  Bucket: used to store away values
    * per account or sub-account
    * stored as durations (seconds) or amounts (currency)
    * with rollover, rollover maximum value or amount, rollover maximum duration / without rollover



Plan parameters:
  Currency

Account or sub-account parameters:
  Discount
