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

package CCNQ::Proxy::npanxx_route;
use base qw(CCNQ::Proxy::npa_route);

=pod
    For each NPANXX you must define the trunk set to use.
    The Route value is the NPANXX to be considered for routing.
    Rank must be an integer starting at 0 (first route) and 
    going up.
    <p>
    Target must be a "host:port" value indicating what host
    (IP address or DNS name) to use, and what port to use on
    the destination (use 0 to force DNS SRV resolution; otherwise
    in most cases the value should be 5060).
=cut


sub _len { 6 }

1;