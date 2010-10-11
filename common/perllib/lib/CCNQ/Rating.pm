package CCNQ::Rating;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Math::BigFloat;

use AnyEvent;
use CCNQ::AE;
use CCNQ::Rating::Rate;
use CCNQ::Rating::Event;
use CCNQ::Rating::Event::Rated;

use Logger::Syslog;

sub rate_cbef {
  my ($flat_cbef,$plan) = @_;
  # debug("CCNQ::Rating::rate_cbef() started");

  my $cbef = new CCNQ::Rating::Event($flat_cbef);
  my $rcv = AE::cv;

  # Return immediately on invalid flat_cbef
  $cbef or do { $rcv->send(), return $rcv };

  CCNQ::Rating::Rate::rate_cbef($cbef,$plan)->cb(sub{
    # debug("CCNQ::Rating::rate_cbef() rating done");

    my $rated_cbef = CCNQ::AE::receive(@_);
    $rcv->send($rated_cbef && CCNQ::Rating::Event::Rated->new($rated_cbef));
  });
  return $rcv;
}

'CCNQ::Rating';
