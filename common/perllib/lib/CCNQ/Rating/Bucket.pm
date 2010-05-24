package CCNQ::Rating::Bucket;
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

Bucket-related data is stored in two different locations:
  - metadata (bucket-level data) is stored in the billing database;
  - bucket instances are stored in a separate bucket database.

=cut
use strict; use warnings;

sub _bucket_id { return join('/','bucket',@_) }

use AnyEvent;
use Math::BigFloat;
use CCNQ::CouchDB;
use CCNQ::AE;

=head2 new($name)

Do no forget to call ->load() on the newly created object.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($name) = @_;
  my $self = { _name => $name };
  return bless $self, $class;
}

=head2 load()

Loads the metadata from the billing database.

=cut

sub load {
  my ($self) = @_;
  my $rcv = AE::cv;
  CCNQ::Billing::billing_retrieve({ _id => _bucket_id($self->base_name) })->cb(sub{
    my $rec = CCNQ::AE::receive(@_);
    if($rec) {
      for (qw(use_account currency increment decimals cap)) {
        $self->{$_} = $rec->{$_};
      }
    }
    $rcv->send;
  });
  return $rcv;
}

sub short_name {
  my ($self,$cbef) = @_;
  return $self->use_account
    ? $cbef->{account}
    : $cbef->{account}.'/'.$cbef->{account_sub};
}

sub base_name {
  my ($self) = @_;
  return $self->{_name};
}

sub full_name {
  my ($self,$cbef) = @_;
  return join('/',$self->base_name,$self->short_name($cbef));
}

=head2 ->get_instance($cbef)

Retrieves the bucket instance from the bucket database.

=cut

sub get_instance {
  my ($self,$cbef) = @_;
  return $self->_retrieve($self->full_name($cbef));
}

=head2 ->set_instance_value($instance,$value)

Saves an updated bucket instance into the bucket database.
(The instance must previously have been retrieved using get_instance.)

=cut

sub set_instance_value {
  my ($self,$instance,$value) = @_;
  # Values are always stored properly rounded
  $value = $self->round_down($value);
  # The bucket value can never exceed its cap if (it's defined).
  if(defined($self->cap) && $value > $self->cap) {
    $value = $self->cap;
  }
  $instance->{value} = $value;
  return $self->_store($instance);
}

=head2 use($cbef,$value)

  Where $value can be:
    - a currency amount
    - a duration, in seconds

  Decrements the bucket by the value indicated.
  Returns the number of units that were allocated from the bucket.

=cut

sub use {
  my $self = shift;
  my ($cbef,$value) = @_;

  my $rcv = AE::cv;

  my $cv_failed = sub {
    $rcv->send(Math::BigFloat->bzero);
    return $rcv;
  };

  if($value <= 0) {
    return $cv_failed;
  }

  # If the bucket stores money, make sure the currency is the proper one.
  if($self->currency && $cbef->currency ne $self->currency) {
    error("Invalid currency");
    return $cv_failed;
  };

  $value = $self->round_up($value);

  $self->get_instance($cbef)->cb(sub{
    my $bucket_instance = CCNQ::AE::receive(@_);
    return $cv_failed->() unless $bucket_instance;

    my $current_bucket_value = $bucket_instance->{value};

    if($current_bucket_value < $value) {
      $self->set_instance_value($bucket_instance,Math::BigFloat->bzero)->cb(sub{
        if(CCNQ::CouchDB::receive_ok(undef,@_)) {
          $rcv->send($current_bucket_value);
        } else {
          $cv_failed->();
        }
      });
    } else {
      my $remaining = $current_bucket_value - $value;
      $self->set_instance_value($bucket_instance,$remaining)->cb(sub{
        if(CCNQ::CouchDB::receive_ok(undef,@_)) {
          $rcv->send($value);
        } else {
          $cv_failed->();
        }
      });
    }
  });
  return $rcv;
}

=pod

replenish {
  currency
  value
  account
  account_sub
}

=cut

sub replenish {
  my $self = shift;
  my ($params) = @_;

  use Logger::Syslog;
  debug("replenish: ".CCNQ::AE::pp($params));

  my $rcv = AE::cv;

  if($params->{value} <= 0) {
    debug("replenish: negative value");
    $rcv->send( { error => 'Negative value' } );
    return $rcv;
  }

  # If the bucket stores money, make sure the currency is the proper one.
  if($self->currency && $params->{currency} ne $self->currency) {
    debug("replenish: invalid currency");
    $rcv->send( { error => 'Invalid currency' } );
    return $rcv;
  };

  $self->get_instance($params)->cb(sub{
    my $bucket_instance = CCNQ::AE::receive(@_);

    debug("replenish get_instance: ".CCNQ::AE::pp($bucket_instance));

    my $current_bucket_value = $bucket_instance ? $bucket_instance->{value} : Math::BigFloat->bzero;
    $current_bucket_value += $params->{value};

    # Create a new bucket-instance if none was available.
    $bucket_instance ||= {
      _id         => $self->full_name($params),
      account     => $params->{account},
      account_sub => $params->{account_sub}
    };

    debug("replenish set_instance_value: ".CCNQ::AE::pp($bucket_instance));
    my $cv1 = $self->set_instance_value($bucket_instance,$current_bucket_value);
    $cv1->cb(sub{
      my $r = CCNQ::AE::receive(@_);
      $rcv->send($r);
      debug("replenish completed: ".CCNQ::AE::pp($r));
    });
  });

  debug("replenish: return ".CCNQ::AE::pp($rcv));
  return $rcv;
}

sub _retrieve {
  my ($self,$key) = @_;
  return CCNQ::Rating::Bucket::DB::retrieve_bucket_instance($key);
}

sub _store {
  my ($self,$instance) = @_;
  return CCNQ::Rating::Bucket::DB::update_bucket_instance($instance);
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
  return shift->{currency};
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
  return shift->{decimals} || 0;
}

=head2 increment

The integer increment to use for storing and substracting values from
the bucket.

=cut

sub increment {
  return shift->{increment} || 0;
}

=head2 cap

The maximum number of either monetary unit or seconds that can be
stored in a bucket instance.

=cut

sub cap {
  return shift->{cap};
}

=head2 use_account

If true, use the account as the key.
Otherwise, use the account+account_sub as the key.

=cut

sub use_account {
  return shift->{use_account};
}

'CCNQ::Rating::Bucket';
