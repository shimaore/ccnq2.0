package CCNQ::Portal::I18N;
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

use Filter::Simple;

=pod


  We use macros so that e.g.
     _("....")_
  can use the local $session to gather $session->current_locale().

=cut

# See http://www.unix.com/shell-programming-scripting/70177-perl-regex-help-matching-parentheses-2.html
# or http://search.cpan.org/dist/perl-5.10.0/pod/perl5100delta.pod#Regular_expressions

sub loc {
  return CCNQ::Portal->current_session->locale->loc(@_);
}

FILTER {
  s{_\((.*?)\)_}{ (CCNQ::Portal::I18N::loc($1)) }g;
};

1;
