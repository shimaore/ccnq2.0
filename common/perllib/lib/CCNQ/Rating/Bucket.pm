package Rating::Bucket;
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

=pod
Buckets can store:
 - seconds of usage
 - money (with currency)
with either:
 - a given number of decimals
 - or a given increment
and can do so:
 - with or without rollover
 - if with rollover, the rollover can be capped (maximum value stored in the bucket)
and are referenced by:
 - a bucket name (arbitrary)
 - combined with an account or an account_sub (depending on the bucket)

Note:
  Typically (for most Western currencies) you should set
    decimals = 2
  For per-second buckets
    decimals = 0 (the default), increment = 1
  For per-minute buckets
    decimals = 0 (the default), increment = 60

=cut

use Math::BigFloat;

=pod

  Probably use a CouchDB as the underlying storage?

=cut

sub name {
  my ($self,$cbef) = @_;
  return $self->use_account
    ? $cbef->account
    : $cbef->account.'/'.$cbef->account_sub;
}

=head2 get_value

  Returns either the currency amount, or number of seconds.

=cut

sub get_value {
  my ($self,$cbef) = @_;
  my $value = $self->_retrieve($self->name($cbef));
}

sub set_value {
  my ($self,$cbef,$value) = @_;
  # Values are always stored properly rounded
  my $value = $self->round_down($value);
  # The bucket value can never exceed its cap if (it's defined).
  if(defined($self->cap) && $value > $self->cap) {
    $value = $self->cap;
  }
  $self->_store($self->name($cbef),$value);
}

=head2 use($cbef,$value)

  Where $value can be:
    - a currency amount
    - a duration, in seconds

  Returns zero if the entire amount could be allocated from the bucket.
  Otherwise returns the number of currency units or seconds which could not
  be allocated.

=cut

sub use {
  my $self = shift;
  my ($cbef,$value) = @_;

  return Math::BigFloat->bzero if $value <= 0;

  # If the bucket stores money, make sure the currency is the proper one.
  die "Invalid currency" if $self->currency && $cbef->currency ne $self->currency;

  $value = $self->round_up($value);

  my $current_bucket_value = $self->get_value($cbef);

  if($current_bucket_value < $value) {
    $self->set_value($cbef,Math::BigFloat->bzero);
    return $value - $current_bucket_value;
  } else {
    my $remaining = $current_bucket_value - $value;
    $self->set_value($cbef,$remaining);
    return Math::BigFloat->bzero;
  }
}

=head2 use_account

If true, use the account as the key.
Otherwise, use the account+account_sub as the key.

=cut

sub use_account {
  my ($self,$use_account) = @_;
  if(defined($use_account)) {
    $self->{use_account} = $use_account;
  } else {
    return $self->{use_account};
  }
}

sub _retrieve {
  my $self = shift;
  my ($key) = @_;
  XXX
}

sub _store {
  my $self = shift;
  my ($key,$value) = @_;
  XXX
}

=head1 Bucket type

  currency is defined     => money-based bucket
  currency is not defined => second-based bucket

=cut

=head2 currency

  Return a valid currency name if this buckets stores money.
  Return undef otherwise.

=cut

sub currency {
  return $self->{currency};
}

=head2 rounding

Rounds using the number of decimals if applicable.
Otherwise rounds using the increment if applicable.

=cut

sub round_down {
  my ($self,$value) = @_;
  if($self->decimals) {
    return $value->ffround(-$self->decimals,'-inf');
  }
  if($self->increment) {
    return $self->increment * ($value/$self->increment)->bfloor();
  }
  returm $value;
}

sub round_up {
  my ($self,$value) = @_;
  if($self->decimals) {
    return $value->ffround(-$self->decimals,'+inf');
  }
  if($self->increment) {
    return $self->increment * ($value/$self->increment)->bceil();
  }
  returm $value;
}

=head2 decimals

The number of decimal digits to round up or down to.

=cut

sub decimals {
  return $self->{decimals} || 0;
}

=head2 increment

The integer increment to use for storing and substracting values from
the bucket.

=cut

sub increment {
  return $self->{increment} || 0;
}

=head2 cap

The maximum number of either monetary unit or seconds that can be
stored in a bucket instance.

=cut

sub cap {
  return $self->{cap};
}

'CCNQ::Rating::Bucket';
