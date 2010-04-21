package CCNQ::Rating::Event::Rated;
use base 'CCNQ::Rating::Event';

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = shift;
  return bless $self, $class;
}

sub compute_taxes {
  my ($self) = @_;
  $self->{taxable_cost} = $self->cost;

  # For each tax jurisdiction, compute the amount owed
  # Note: this is applied to the total cost, we don't
  #       know (yet) how to differentiate tax rates on
  #       duration_cost vs count_cost.
  for my $tax (@{$self->tax || []}) {
    for my $jurisdiction (keys %{$tax}) {
      my $rate = $tax->{$jurisdiction};
      my $tax_amount = $self->rounding($self->taxable_cost * ($rate/100.0));
      $self->{taxes}->{$jurisdiction} += $tax_amount;
      $self->{tax_amount} += $tax_amount;
    }
  }

  $self->{total_cost} = $self->taxable_cost + $self->tax_amount;
}

sub as_json {
  return encode_json($self->cleanup);
}

'CCNQ::Rating::Event::Rated';
