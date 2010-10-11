package portal;
# Copyright (C) 2010  Stephane Alnet
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
use strict; use warnings;

use Dancer;

use CCNQ::Portal::Site;
use CCNQ::Portal::Render;
use CCNQ::Portal::Auth::CouchDB;

my $site = CCNQ::Portal::Site->new(
  default_locale  => 'en-US',
  security        => CCNQ::Portal::Auth::CouchDB->new(),
  default_content => CCNQ::Portal::Render::default_content
);

use CCNQ::Portal::Content;

use CCNQ::Portal;
CCNQ::Portal->import($site);

true;
