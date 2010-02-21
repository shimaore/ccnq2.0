# Tests for inclusion of different CCQN modules.

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
use Test::More import => ['!pass'];

use_ok 'Dancer';
set(session => 'Simple');

require_ok ("CCNQ::Portal");
require_ok ("CCNQ::Portal::Site");
require_ok ("CCNQ::Portal::Outer::AccountSelection");

my $site = CCNQ::Portal::Site->new(default_locale => 'en-US');
ok($site,'Created site');
CCNQ::Portal->set_site($site);
ok(CCNQ::Portal->site,'Site is registered');

# Make sure we can actually generate a form.
my $form = CCNQ::Portal::Outer::AccountSelection::form();
ok(defined($form),'account selection form');
ok(defined($form->render()),'account selection form render');

done_testing();
1;
