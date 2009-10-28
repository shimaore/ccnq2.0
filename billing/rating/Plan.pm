
sub days_in_billing_period {
  my $self = shift;
  return $self->billing->days_in_billing_period;
}

sub seconds_in_minute {
  return 60;
}

sub compute_rate {
  my $self = shift;
  my ($rate) = @_;
  return $rate if $rate->{unit} eq 1;
  return $rate / $self->days_in_billing_period if $rate->{unit} eq 'billing_period';
  return $rate / $self->seconds_in_minute if $rate->{unit} eq 'minute';
}


=pod

  A Plan is a function that takes a CBEF and translate it into a Rate CBEF,
  adding (at least) the following information:

    currency
    amount    (pre-tax)
    tax = { jurisdiction => percentage }

  In some cases a Plan will use a Rating Table in order to do prefix-based
  lookups; two parameters need to be determined for this:

    rating_table    the name of the rating table to be used
    rating_key      the key to use for prefix-based-lookup

=cut


  locate_event_type_cost_destination {
    my ($self,$event_type,$to_e164) = @_;
    
  }


  Issues the Plan needs to address:

    which currency is used (normally statically assigned to the plan)
    how is the amount computed? which leads to:
      is the event_type billable? (e.g. falls into a bucket?)
        this might be more complicated for duration-based event_type's
      locate the count-based rate
        in most cases this would be a static amount per event_type,
        however (eg for France) a "coût d'établissment de l'appel" may apply to a call, which will be different based on the destination (to_e164).
        same in the US for (eg) directory assistance
        so:
            locate_event_type_cost(event_type)  # Use only the event_type
          + locate_event_type_cost_destination(event_type,to_e164)  # Use a rating table
        Note: the denominator might be "billing_period" (it is available from the rating table)
      turn the actual duration into a billable_duration
        may depend on source and destination
      locate the duration-based rate
        is a rating_table applicable?
          how is the rating_table selected?
            generally provided by the plan itself
          how is the rating_key computed?
            this will generally be the called number (to_e164)
        so:
            locate_event_type_duration_rate(event_type)
          + locate_event_type_duration_rate_destination(event_type,to_e164)
      multiply by count
      multiply by margin factor
    what taxes are applicable?
      the plan may include "static" tax elements (eg French taxes)
      or per-destination taxes (eg US taxes)
