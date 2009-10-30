Build modules?

sub rate_cbef {
  my ($cbef,$plan) = @_;
  # ... do the preparation work (e.g. locate plan currency)
  $cbef->{currency} = $plan->currency;

  # Run through the guards/actions
  for my $rating_step ($plan->rating_steps) {
    my $guards = $rating_step->guards;
    next if $guards && !apply_cbef_conditions($cbef,$guards);
    my $actions = $rating_step->actions;
    last if apply_cbef_actions($cbef,$actions);
  }

  # Save the new CBEF and update per account/sub-account summaries.
}


sub apply_cbef_conditions {
  my ($cbef,$guards) = @_;
  # $guards is an arrayref of guards; a guard is [ guard_name, guard_parameters ]
  # All guards must be true for the actions to be applied.
  # Note: if tables are found, they MUST be Rating::Table instances, not the table names.
  for my $guard (@{$guards}) {
    my @guard = @{$guard};
    my $sub = cbef_conditions->{shift @guard};
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


use Math::BigFloat;
use constant seconds_per_minute => Math::BigFloat->new(60);


sub add_duration_rate {
  my ($cbef,$rate) = @_;
  $rate = Math::BigFloat->new($rate);

  my $initial = $cbef->{initial_duration};

  $cbef->{billable_duration} = $cbef->duration * $cbef->billable_count;

  my $billed_seconds = 0;

  if($cbef->{billable_duration}) {
    $billed_seconds += $initial;
  }

  if($cbef->{billable_duration} > $initial) {
    my $increments = ($cbef->{duration}-$initial)/$cbef->{increment_duration};
    my $seconds = $increment->bceil() * $cbef->{increment_duration};
    $billed_seconds += $seconds;
  }

  if($cbef->{duration_bucket}) {
    $billed_seconds = $cbef->{duration_bucket}->($cbef,$billed_seconds);
  }

  my $duration_cost = $billed_seconds * $rate/seconds_per_minute;

  my $cost = $cbef->rounding( $duration_cost );
  $cost = $cbef->{cost_bucket}->use($cost) if $cbef->{cost_bucket};
  $cbef->{duration_cost} += $cost;
  $cbef->{cost}          += $cost;
}

sub add_count_cost {
  my ($cbef,$amount) = @_;
  $amount = Math::BigFloat->new($amount);

  my $cost = $cbef->rounding( $amount * $cbef->billable_count );
  $cost = $cbef->{cost_bucket}->use($cost) if $cbef->{cost_bucket};
  $cbef->{count_cost}    += $cost;
  $cbef->{cost}          += $cost;
}

sub add_jurisdiction {
  my ($cbef,$rec) = @_;
  push(@{$cbef->{_jurisdiction}},$rec);
}

use constant cbef_conditions => {

=pod
  Conditions
    Event type is [type]  (event_type == $1)
=cut

  event_type_is => sub {
    my ($cbef,$event_type) = @_;
    return $cbef->event_type eq $event_type;
  },

=pod
    National calls        (to.country == from.country)
=cut
  national_call => sub {
    my ($cbef) = @_;
    return $cbef->to->country eq $cbef->from->country;
  },

=pod
    International calls   (to.country != from.country)
=cut
  international_call => sub {
    my ($cbef) = @_;
    return $cbef->to->country ne $cbef->from->country;
  },

=pod
    US Inter-state        (to.country == us && from.country == us && to.state != from.state)
=cut
  us_inter_state  => sub {
    my ($cbef) = @_;
    return $cbef->to->country eq 'us' && $cbef->from->country eq 'us' && $cbef->to->us_state ne $cbef->from->us_state;
  },

=pod
    US Intra-state        (to.country == us && from.country == us && to.state == from.state)
=cut
  us_intra_state  => sub {
    my ($cbef) = @_;
    return $cbef->to->country eq 'us' && $cbef->from->country eq 'us' && $cbef->to->us_state eq $cbef->from->us_state;
  },

=pod
    To [country]          (to.country == $1)
=cut
  to_country => sub {
    my ($cbef,$country) = @_;
    return $cbef->to->country eq $country;
  },

=pod
    From [country]        (from.country == $1)
=cut
  from_country => sub {
    my ($cbef,$country) = @_;
    return $cbef->from->country eq $country;
  },

=pod
    To [table]            (table->lookup(to.e164))
=cut
  to_table => sub {
    my ($cbef,$table) = @_;
    return $table->lookup($cbef->to->e164}) ? 1 : 0;
  },

=pod
    From [table]          (table->lookup(from.e164))
=cut
  from_table => sub {
    my ($cbef,$table) = @_;
    return $table->lookup($cbef->from->e164) ? 1 : 0;
  },

=pod
    Day is [mon,tue,...]  (dow(start_date) == $1)
    Call started between time1 and time2
=cut

=pod
    Zero call duration
=cut
  zero_duration => sub {
    my ($cbef) = @_;
    return $cbef->duration == 0;
  },

=pod
    Non-zero call duration
=cut
  non_zero_duration => sub {
    my ($cbef) = @_;
    return $cbef->duration > 0;
  },

=pod
    Call duration < [value]
=cut
  shorter_than => sub {
    my ($cbef,$duration) = @_;
    return $cbef->duration < $duration;
  },

=pod
    Zero count
=cut
  zero_count => sub {
    my ($cbef) = @_;
    return $cbef->count == 0;
  },

=pod
    Non-zero count
=cut
  non_zero_count => sub {
    my ($cbef) = @_;
    return $cbef->count > 0;
  },



};

use constant cbef_actions => {
=pod
  Per-CBEF Actions
=cut

=pod
    Is billable
=cut
  is_billable => sub {
    my ($cbef) = @_;
    $cbef->{billable_count} = $cbef->{count};
  },

=pod
    Is non-billable
=cut
  is_non_billable => sub {
    my ($cbef) = @_;
    $cbef->{billable_count} = 0;
  },

=pod
    Use minutes from bucket: [bucket]
=cut
  use_minutes_from_bucket => sub {
    my ($cbef,$bucket) = @_;
    $cbef->{duration_bucket} = $bucket;
  },

=pod
    Use amount from bucket: [bucket]
=cut
  use_amount_from_bucket => sub {
    my ($cbef,$bucket) = @_;
    $cbef->{cost_bucket} = $bucket;
  },



=pod
    Set initial period: [initial] with increment period [increment]
=cut
  set_periods_values => sub {
    my ($cbef,$initial_duration,$increment_duration) = @_;
    $cbef->{initial_duration}   = $initial_duration;
    $cbef->{increment_duration} = $increment_duration;
  },

=pod
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

=pod
    Add count-based cost [amount]
=cut
  add_count_cost => sub {
    my ($cbef,$amount) = @_;
    add_count_cost($cbef,$amount);
  },

=pod
    Add count-based cost using [table] using destination number
=cut
  add_count_cost_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $r = $table->lookup($cbef->to->e164);
    if($r) {
      add_count_cost($cbef,$r->{count_cost});
    }
  },

=pod
    Add duration-based rate [per-minute-rate]
=cut
  add_duration_rate => sub {
    my ($cbef,$rate) = @_;
    add_duration($cbef,$rate);
  },

=pod
    Add duration-based rating using [table] with rating key: {to.e164, ...}  [table must use same currency as plan]
=cut
  add_duration_rate_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $r = $table->lookup($cbef->to->e164);
    if($r) {
      add_duration($cbef,$r->{duration_rate});
    }
  },


=pod
    Add jurisdiction [jurisdiction] with rate [rate]
=cut
  add_jurisdiction => sub {
    my ($cbef,$jurisdiction,$rate) = @_;
    add_jurisdiction($cbef,{ $jurisdiction => $rate });
  }

=pod
    Add jurisdiction using [table] with key: {to.e164, ...}
=cut
  add_jurisdiction_table_to_e164 => sub {
    my ($cbef,$table) = @_;
    my $r = $table->lookup($cbef->to->e164);
    if($r) {
      add_jurisdiction($cbef,{ $jurisdiction => $rate });
    }
  },



    Difficult: rating periods -- in some cases, calls are rated differently based on time periods.

}

Add duration to counter: [counter]
Add billable duration to counter: [counter]
Add



Global Actions (applied at the sub-account or account level once all CBEFs have been processed)



Other objects:
  RatingTable: prefix-based values lookup (returns a record of values)
  Bucket: used to store away values
    * per account or sub-account
    * stored as values (e.g. minutes) or amounts
    * with rollover, rollover maximum value or amount, rollover maximum duration / without rollover



Plan parameters:
  Currency

Account or sub-account parameters:
  Discount
