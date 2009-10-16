package CCNQ::Proxy::report_call;
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

        This report shows details for a single call attempt.

HTML
}

sub form
{
    my $self = shift;
    return (
        'Server'        => [ map { $_ => $_ } $self->list_of_servers],
        'Timestamp'     => [ '' => 'Realtime', map { $_ => $_ } $self->list_of_timestamps ],
        'CallID'       => 'text',
    );
}

sub do_form
{
    my $self = shift;
    
    my @params = $self->vars;
    our %params = @params;

    my $callid      = $params{callid};
    die 'No CallID' unless defined $callid;
    $callid =~ s/[\s'"\\\$]//g;

    $self->_do_command_table('invite-single.pl',$callid);
}

1;