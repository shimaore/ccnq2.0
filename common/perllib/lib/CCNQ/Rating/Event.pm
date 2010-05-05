# CCNQ/Rating/Event.pm
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

package CCNQ::Rating::Event::Number;

use CCNQ::Rating::Table;
use constant e164_to_location_table => 'e164_to_location';
use constant e164_to_location => CCNQ::Rating::Table->new(e164_to_location_table);

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = { e164 => shift };
  return bless $self, $class;
}

sub e164 {
  return $_[0]->{e164};
}

sub location {
  $self->{location} = e164_to_location->lookup($self->e164)
    if !exists($self->{location});
  return $self->{location};
}

sub country {
  my ($self) = @_;
  return $self->location && $self->location->{country};
}

sub us_state {
  my ($self) = @_;
  return $self->location && $self->location->{us_state};
}


package CCNQ::Rating::Event;

=pod

Common Billing Element Format (CBEF)

  All CDRs, logs, and activity-based events are aggregated.
  The aggregated files are classified by type (e.g. FreeSwitch CDRs, etc.) and then fed to different Mediation processors based on their content.
  There is a Null Mediation processor for records which are already in CBEF format.

  The Billing Elements are then fed into the Rating engine (using the CBEF format).

  The file format is tab-delimited UTF-8 data. The first line in each file is used to indicate the fields names.
  (If a Mediation processor doesn't know which fields will be needed, it should provide all the fields it knows about.)
  If a field is empty (two tabs around it) it is treated as undefined/unassigned (i.e. the empty string is treated as undef).

* start_date            YYYYMMDD (local time)
* start_time            HHMMSS   (local time)
* timestamp             (unix epoch-based timestamp, used for correlation with e.g. logs)
* collecting_node       (DNS, IP, or other name for the node that collected the element) -- inserted by the aggregator

* account               (opaque account number)
* account_sub           (opaque sub account, e.g. SIP trunk ID)
* event_type            (opaque event type; the "element rates and conditions" DB will provide information on how to handle it)
  event_description     (plain-text description of the event that caused the Element to be created) [deprecated]
  request_uuid          (uuid of the Request that created the Element)

    For all events we collect an event count:
  count           number of events (e.g. number of SMS, number of Mo transfered, etc.)
                  normally "1" for duration-based events; "0" if the event (call) was not connected

    For calls we collect the following information:
  duration        duration in seconds (zero duration is non-billed call)
  from_e164       (E.164 number without a "+" sign)
  to_e164         (E.164 number without a "+" sign)

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = shift;
  return bless $self, $class;
}

use Scalar::Util qw(blessed);

sub cleanup {
  # Remove all the fields that start with _
  my $self = shift;
  if(!defined($self)) {
    return undef;
  }
  if(UNIVERSAL::isa($self, "ARRAY")) {
    return [map { cleanup($_) } @{$self}];
  }
  if(UNIVERSAL::isa($self, "HASH")) {
    return { map { cleanup($_) => cleanup($self->{$_}) } grep { /^[^_]/ } keys %{$self} };
  }
  if(blessed($self) =~ /^Math::Big/) {
    return ''.$self->bstr();
  }
  if(blessed($self)) {
    return 'object '.blessed($self);
  } else {
    return "$self";
  }
  # For objects, assume they are hashref based.
  # return cleanup(%{$self});
}


sub to {
  my ($self) = @_;
  $self->{_to} ||= new Rating::Event::Number($self->{to_e164});
  return $self->{_to};
}

sub from {
  my ($self) = @_;
  $self->{_from} ||= new Rating::Event::Number($self->{from_e164});
  return $self->{_from};
}

sub rounding {
  my ($self,$amount) = @_;
  if($self->decimals) {
    return $amount->ffround(-$self->decimals,'+inf');
  } else {
    return $amount;
  }
}

our $AUTOLOAD;

use Logger::Syslog;

sub DESTROY { }

sub AUTOLOAD {
  my ($self) = @_;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;
  # Return the value if any
  return $self->{$name} if exists($self->{$name});
  # Unknown field error
  debug(ref($self).": Unknown field $name");
  return undef;
}

'CCNQ::Rating::Event';
