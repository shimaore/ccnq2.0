package CCNQ::Proxy::report_realtime;
# Copyright (C) 2006, 2007  Stephane Alnet
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
#

#
# For more information visit http://carrierclass.net/
#
use strict; use warnings;

use base qw(CCNQ::Proxy::report);

sub doc
{
    return <<'HTML';

        This report shows call attempts and call attempt outcomes per hour for the
        current running set of logs.
    <br>
        Notes:
        The last column "Calls" indicate the total number of actual call attempts.
        The 200 column relates to completed calls.
        The 487 column relates to abandonned calls.
        The 486 column relates to busy calls.
        The 404 and 480 columns relates to calls with invalid destinations.
    <br>
        Other columns should show little to no activity.
    <br>
        Note: the subscriber name may be a regular expression.

HTML
}

sub form
{
    my $self = shift;
    return (
        'Server'        => [ map { $_ => $_ } $self->list_of_servers],
        'Timestamp'     => [ '' => 'Realtime', map { $_ => $_ } $self->list_of_timestamps ],
        'Account'       => 'text',
        'From_Subscriber' => 'text',
        'To_Subscriber'   => 'text',
    );
}

sub do_form
{
    my $self = shift;

    my @params = $self->vars;
    our %params = @params;

    my $from_subscriber  = $params{from_subscriber};
    $from_subscriber = '' if not defined $from_subscriber;
    die 'Invalid From subscriber name' unless $from_subscriber =~ /^[\w-]*$/;

    my $to_subscriber  = $params{to_subscriber};
    $to_subscriber = '' if not defined $to_subscriber;
    die 'Invalid To subscriber name' unless $to_subscriber =~ /^[\w-]*$/;

    my $account  = $params{account};
    $account = '' if not defined $account;
    die 'Invalid account' unless $account =~ /^[\w-]*$/;

    $self->_do_command_table('invite-outcome.pl',$from_subscriber,$to_subscriber,$account);
}

1;