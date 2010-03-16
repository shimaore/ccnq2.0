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
  for my $tax (@{$cbef->tax || []}) {
    for my $jurisdiction (keys %{$tax}) {
      my $rate = $tax->{$jurisdiction};
      my $tax_amount = $self->rounding($cbef->taxable_cost * ($rate/100.0));
      $cbef->{taxes}->{$jurisdiction} += $tax_amount;
      $cbef->{tax_amount} += $tax_amount;
    }
  }

  $cbef->{total_cost} = $cbef->taxable_cost + $cbef->tax_amount;  
}

sub as_json {
  return encode_json($self->cleanup);
}

'CCNQ::Rating::Event::Rated';
