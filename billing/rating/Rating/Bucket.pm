package Rating::Bucket;

=pod
Buckets can store:
 - minutes of usage
 - seconds of usage
 - money (with currency)
and can do so:
 - with or without rollover
 - if with rollover, the rollover can be capped (maximum value stored in the bucket)
and are referenced by:
 - a bucket name (arbitrary)
 - combined with an account or an account_sub (depending on the bucket)

Buckets only store integer values.
=cut

use Math::BigInt;

=pod

  Probably use a CouchDB as the underlying storage?
  
=cut

sub name {
  my ($self,$cbef) = @_;
  return $self->use_account
    ? $cbef->account 
    : $cbef->account.'/'.$cbef->account_sub;
}

sub get_value {
  my ($self,$cbef) = @_;
  return $self->retrieve($self->name($cbef));
}

sub set_value {
  my ($self,$cbef,$value) = @_;
  $self->store($self->name($cbef),$value);
}

sub use {
  my ($cbef,$value) = @_;
  return $value if $value <= 0;

  $value = $value->bceil;
  $value = Math::BigInt($value);

  my $current_bucket_value = $self->get_value($cbef);
  # If the bucket stores minutes, use the proper multiplier.
  $current_bucket_value *= seconds_per_minute if $self->per_minute;
  # If the bucket stores money, make sure the currency is the proper one.
  die "Invalid currency" if $self->currency && $cbef->currency ne $self->currency;

  if($current_bucket_value < $value) {
    $self->set_value($cbef,Math::BigInt->bzero);
    return $value - $current_bucket_value;
  } else {
    my $remaining = $current_bucket_value - $value;
    $remaining = ($remaining/seconds_per_minute)->bceil() if $self->per_minute;
    $self->set_value($cbef,$remaining);
    return Math::BigInt->bzero;
  }
}

1;