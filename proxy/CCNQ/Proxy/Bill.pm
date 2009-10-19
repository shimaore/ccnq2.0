package CCNQ::Proxy::Bill;
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
use CCNQ::Proxy::Base;

sub _field_names
{
    # Default fields for OpenSIPS 1.2
    # Note: The names are the default from modules/acc/mod_acc.c
    #       The order is given by modules/acc/acc.c
    #       (Look for acc_method_col, etc.)
    my @field_names_12 = qw(
        method
        from_tag
        to_tag
        callid
        sip_code
        sip_reason
        time
    );

    my @cdr_extra = ();

    my @cdr_src = @{CCNQ::Proxy::Base::cdr_extra()};
    while(@cdr_src)
    {
        my $name = shift @cdr_src;
        my $var  = shift @cdr_src;
        push @cdr_extra, $name;
    }
    undef @cdr_src;

    return (@field_names_12,@cdr_extra);
}

1;
