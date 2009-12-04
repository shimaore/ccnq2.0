package CCNQ::I18N;
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
use base 'Locale::Maketext';

our @EXPORT = qw( _ );

use CCNQ::Install;

use constant::defer i18n_directory =>
  sub { File::Spec->catfile(CCNQ::Install::SRC,qw( common i18n )) };

# See http://cpansearch.perl.org/src/DRTECH/Locale-Maketext-Lexicon-0.77/docs/webl10n.html

use Locale::Maketext::Lexicon {
        'en' => ['Auto'],
        '*' => [Gettext => File::Spec->catfile(i18n_directory,qw( *.po )],
        ### Uncomment to decode lexicon entries into Unicode strings
        # _decode => 1,
        ### Uncomment to fallback when a key is missing from lexicons
        _auto   => 1,
        ### Uncomment to use %1 / %quant(%1) instead of [_1] / [quant, _1]
        # _style  => 'gettext',
};

use Lingua::EN::Numbers::Ordinate;
sub en::ord { ordinate($_[1]) }
use Lingua::FR::Numbers::Ordinate;
sub fr::ord { ordinate_fr($_[1]) }

use CCNQ::Portal::CurrentUser;

sub _ {
  if(CCNQ::Portal::current_user) {
    CCNQ::Portal::current_user->loc(@_);
  } else {
    my $lh = __PACKAGE__->get_handle;
    $lh-> maketext(@_);
  }
}

# Could use CCNQ::Install::get_variable().
use constant default_language => 'en-US';

1;
