package CCNQ::Actions::cdr;
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
use strict; use warnings;

use CCNQ::CDR;
use CCNQ::Rating::Event::Rated;

sub _install {
  return CCNQ::CDR::install(@_);
}

sub insert {
  my ($params,$context) = @_;
  my $rated_cbef = CCNQ::Rating::Event::Rated->new($params);
  return CCNQ::CDR::insert($rated_cbef);
}

'CCNQ::Actions::cdr';
