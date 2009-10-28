
Steps in the rating process:

CBEF as received:

  start_date
  start_time
  account
  account_sub
  event_type

Numbers:

  from_e164
  to_e164       destination number, or more generally, which number this relates to

[Note: more generically, there would be a "numbers" fields with entries in it.]

Spent units:

  event_count
  duration

[Note: more generically, there would be a "spent" field with {value,unit} pairs in it.]

Plus the following CBEF elements which are generally not used for rating:

  timestamp
  collecting_node
  event_description
  request_uuid



First the various fields are expanded as needed; e.g.


  # Could use Number::Phone, otherwise use our own DB for states, etc.
  sub expand_number {
    my ($cbef,$role) = @_;
    my $info = locate_number_info($cbef->{$role.'_e164');
    $cbef->{$role.'_label'}   = $info->{label};
    $cbef->{$role.'_country'} = $info->{country};
    $cbef->{$role.'_state'}   = $info->{state}; # Mostly useful in the US for intra-state vs inter-state determination
    return;
  }

  expand_number($cbef,'from');
  expand_number($cbef,'to');


Then the account+account_sub is used to locate a specific Plan; the Plan is then used to run the rating.


  my $plan = lookup_plan_for($cbef->{account},$cbef->{account_sub});
  $plan->apply($cbef);
  return $cbef; # A Rated CBEF









use constant mappers => {
  zero => {
    my ($value) = @_;
    return 0;
  },
  base => {
    my ($value,$base_cost) = @_;
    return $base_cost;
  },
  base_increment => {
    my ($value,$base,$base_cost,$increment,$increment_cost) = @_;
    return $base_cost + $increment_cost * max( 0, ceiling( ($value-$base) / $increment ) );
  }
}










event_types:
  connected_inbound_call
  connected_outbound_call
  connected_onnet_call
  failed_inbound_call
  failed_outbound_call
  failed_onnet_call
  sms
  dids_in_use
  activated_did # On the first day of use.

rate_tables (examples):
  sms:free-week-ends+1000-free-monthly+6c-extra


filter(event) =>
  rate_table
  category+subcategory

bucket = per subcategories (can aggregate many)

category: e.g. voice alls, SMS, internet connection
  sub_category: e.g. week-end SMS, etc.
  -> maintain buckets per sub_category + unit types

rates:
  essentially a duration is first converted (once the rate is determined)
  into a billable_base (based on call minimum duration) + billable_count
  
  
sub duration_to_count {
  my ($duration,$minimum_duration,$)
}







use constant record_handler = {
  # "event_type_handler"
  'sms' => sub {
    my ($cbef) = @_;
    my $rate = locate_rate_single($cbef->{account},$cbef->{account_sub},$cbef->{}, ...)
  },
  'connected_call' => sub {
    my ($cbef) = @_;
    my $filters = compute_filters($cbef);
    my $rate = locate_rate_filtered($cbef->{account},$cbef->{account_sub},$filters,...)
  },
};

sub rate_handler {
  my ($cbef,$rate) = @_;
  $cbef->{currency} = $rate->{currency};

  $cbef->{count_cost}    = $cbef->{billable_count} * $rate->{count_cost} + $rate-> if $cbef->{billable_count};
  $cebf->{duration_cost} = $cbef->{billable_duration} * $rate
}


sub rater {
  my ($cbef) = @_;

  my $event_type = $cbef->{event_type};
  return record_handler->{$event_type}->($cbef);
}

