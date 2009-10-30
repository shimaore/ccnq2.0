
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



Then the account+account_sub is used to locate a specific Plan; the Plan is then used to run the rating.


  my $plan = lookup_plan_for($cbef->{account},$cbef->{account_sub});
  $plan->apply($cbef);
  return $cbef; # A Rated CBEF







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

