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

use constant BUCKET_NAME_PREFIX => 'bucket';

use AnyEvent;
use Math::BigFloat;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($name) = @_;
  my $self = { _name => $name };
  return bless $self, $class;
}

=pod

  Probably use a CouchDB as the underlying storage?

=cut

sub short_name {
  my ($self,$cbef) = @_;
  return $self->use_account
    ? $cbef->account
    : $cbef->account.'/'.$cbef->account_sub;
}

sub base_name {
  my ($self) = @_;
  return join('/',BUCKET_NAME_PREFIX,$self->{_name});
}

sub full_name {
  my ($self,$cbef) = @_;
  return join('/',$self->base_name,$self->short_name($cbef));
}

=head2 get_value

  Returns either the currency amount, or number of seconds.

=cut

sub get_value {
  my ($self,$cbef) = @_;
  return $self->_retrieve($self->full_name($cbef));
}

sub set_value {
  my ($self,$cbef,$value) = @_;
  # Values are always stored properly rounded
  $value = $self->round_down($value);
  # The bucket value can never exceed its cap if (it's defined).
  if(defined($self->cap) && $value > $self->cap) {
    $value = $self->cap;
  }
  return $self->_store($self->full_name($cbef),$value);
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

  my $rcv = AE::cv;
  
  if($value <= 0) {
    $rcv->send(Math::BigFloat->bzero);
    return $rcv;
  }

  # If the bucket stores money, make sure the currency is the proper one.
  die "Invalid currency" if $self->currency && $cbef->currency ne $self->currency;

  $value = $self->round_up($value);

  $self->get_value($cbef)->cb(sub{
    my $current_bucket_value = eval { shift->recv };

    if($current_bucket_value < $value) {
      $self->set_value($cbef,Math::BigFloat->bzero)->cb(sub{
        eval { shift->recv };
        $rcv->send($value - $current_bucket_value);
      });
    } else {
      my $remaining = $current_bucket_value - $value;
      $self->set_value($cbef,$remaining)->cb(sub{
        eval { shift->recv };
        $rcv->send(Math::BigFloat->bzero);
      });
    }
  });
  return $rcv;
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
  my $rcv = AE::cv;
  CCNQ::Provisioning::retrieve_cv({_id=>$key})->cb(sub{
    my $rec = eval { shift->recv };
    $rcv->send($rec && $rec->{result});
  });
  return $rcv;
}

sub _store {
  my $self = shift;
  my ($key,$value) = @_;
  return CCNQ::Provisioning::update_cv({_id=>$key,value=>$value});
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
