package CCNQ::Rating::RatingTable;

# The rating table is a generic tool to store information related to a given prefix.

# Generally speaking, a given rating table will provide two values for each
# lookup:
#   a per_unit value, provided by the table's data
#   a unit name, which is part of the table's metadata (and therefor shared by all values)
# Examples of "unit" names:
#    billing_period       for rates stored per period (e.g. to account for partial month billing of a DID)
#    minute               for rates stored per minute (as is normally the case for duration-based rates)


sub apply {
  my ($self,$rating_key) = @_;
  my $rate = $self->lookup($rating_key);
  return { per_unit => $rate->{rate}, unit => $self->{unit} };
}

1;