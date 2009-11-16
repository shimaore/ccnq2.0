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

package Rating::Event::Number;

use constant e164_to_location_table => 'e164_to_location';
use constant e164_to_location => new Rating::Table(e164_to_location_table);

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = { e164 => shift };
  return bless $self, $class;
}

sub e164 {
  return $_[0]->{e164};
}

sub country {
  my ($self) = @_;
  $self->{location} = e164_to_location->($self->e164)
    if !exists($self->{location});
  return $self->{location} && $self->{location}->{country};
}

sub us_state {
  my ($self) = @_;
  $self->{location} = e164_to_location->($self->e164)
    if !exists($self->{location});
  return $self->{location} && $self->{location}->{country};
}


package Rating::Event;

=pod

Common Billing Element Format (CBEF)

  All CDRs, logs, and activity-based events are aggregated.
  The aggregated files are classified by type (e.g. FreeSwitch CDRs, etc.) and then fed to different Mediation processors based on their content.
  There is a Null Mediation processor for records which are already in CBEF format.

  The Billing Elements are then fed into the Rating engine (using the CBEF format).

  The file format is tab-delimited UTF-8 data. The first line in each file is used to indicate the fields names.
  (If a Mediation processor doesn't know which fields will be needed, it should provide all the fields it knows about.)
  If a field is empty (two tabs around it) it is treated as undefined/unassigned (i.e. the empty string is not valid content).

* start_date            YYYYMMDD (local time)
* start_time            HHMMSS   (local time)
* timestamp             (unix epoch-based timestamp, used for correlation with e.g. logs)
* collecting_node       (DNS, IP, or other name for the node that collected the element) -- inserted by the aggregator

* account               (opaque account number)
  account_sub           (opaque sub account, e.g. SIP trunk ID)
* event_type            (opaque event type; the "element rates and conditions" DB will provide information on how to handle it)
  event_description     (plain-text description of the event that caused the Element to be created)
  request_uuid          (uuid of the Request that created the Element)

    For all events we collect an event count:
  count           number of events (e.g. number of SMS, number of Mo transfered, etc.)
                  normally "1" for duration-based events; "0" if the event (call) was not connected

    For calls we need to collect the following information:
  duration        duration in seconds (zero duration might mean failed call)
  from_e164       +....
  to_e164         +....

    The Rating engine will locate the following information in the ERC-DB for each number involved in a call
    (i.e. from and to, mostly); the actual field names are "from_label", etc.:

  .label          a "human readable" label for the number
  .country        country of the number
  .state          state of the number (used for US intra- vs inter-state billing)
  etc.

    Additionally, calling/called tax jurisdictions might be located at that time.

    At this point extra parameters are computed in order to locate a proper rate for the call.
    For example:

  intrastate
  interstate
  distance
  time_of_day_rule

    A "rate" is a set of filters and a set of parameters. A filter will map a given call into a unique rating table
    which will provide the proper parameters for the call.

    Filters:
      time-of-day
      intra-state vs inter-state
      etc.

    Parameters: (these are the values provided in the "rating tables" generated from the ERC-DB)

  currency
  initial_duration
  initial_cost
  additional_duration
  additional_cost
  count_cost

    Additionally, tax jurisdictions might be located inside the parameters.

    The following values are then computed:

  billable_count      for countable events
  billable_duration   for duration-based events

    The Rating engine does billing at the account_sub level (e.g. contract), if available.
    It will use the rules in the ERC-DB in order to build a new file which will provide for each element the following additional information:

  currency              USD, EUR, etc.
  amount                (standard float with . decimal separator)
  tax_count             (how many tax_rate and tax_amount)
  tax_jurisdiction_1    (opaque jurisdiction reference or name)
  tax_rate_1            (in %)
  tax_amount_1          (in currency)
  tax_jurisdiction_2    (...)
  tax_rate_2            (in %)
   (etc.)

   The Rating engine might generate 0 amount records if (e.g.) the call is included in a plan, or is a toll-free call.

=cut

sub process {
  my ($fh,$cb) = @_;
  Rating::Process::process($fh, sub {
    my ($cbef) = @_;
    bless $cbef;
    $cb->($cbef);    
  });
}

sub dump {
  # Dump all the fields that do not start with _
  # Then dump to->e164, from->e164, and _jurisdiction, which is an arrayref of
  # { jurisdiction_name => percentage } hashrefs.
}


sub to {
  my ($self) = @_;
  $self->{_to} ||= new Rating::Event::Number($self->{to_e164});
  return $self->{_to};
}

sub from {
  my ($self) = @_;
  $self->{_from} ||= new Rating::Event::Number($slef->{from_e164});
  return $self->{_from};
}

sub rounding {
  my ($self,$amount) = @_;
  if(defined $self->decimals) {
    return $amount->precision(-$self->decimals);
  } else {
    return $amount;
  }
}

our $AUTOLOAD;

use Logger::Syslog;

sub AUTOLOAD {
  my ($self) = @_;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;
  # Return the value if any
  return $self->{$name} if exists($self->{$name});
  # Unknown field error
  error("Unknown field $name");
  return undef;
}

1;