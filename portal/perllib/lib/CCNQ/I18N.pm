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

use constant CCNQ_PORTAL_MAKEFILE_MODULE_NAME => 'CCNQ-Portal';
use constant i18n_base => File::ShareDir::dist_dir(CCNQ_PORTAL_MAKEFILE_MODULE_NAME);
use constant i18n_directory => File::Spec->catfile(i18n_base,qw( i18n ));
use constant i18n_gettext_location => File::Spec->catfile(i18n_directory,qw( *.po ));

# See http://cpansearch.perl.org/src/DRTECH/Locale-Maketext-Lexicon-0.77/docs/webl10n.html

use Locale::Maketext::Lexicon {
        'en' => ['Auto'],
        '*' => [Gettext => i18n_gettext_location],
        ### Uncomment to decode lexicon entries into Unicode strings
        # _decode => 1,
        ### Uncomment to fallback when a key is missing from lexicons
        _auto   => 1,
        ### Uncomment to use %1 / %quant(%1) instead of [_1] / [quant, _1]
        # _style  => 'gettext',
};

use Lingua::EN::Numbers::Ordinate;
sub en::ord { ordinate($_[1]) }
use Lingua::FR::Numbers qw(number_to_fr ordinate_to_fr);
sub fr::numf{ number_to_fr($_[1]) }
sub fr::ord { ordinate_to_fr($_[1]) }
#use Lingua::FR::Numbers::Ordinate;
#sub fr::ord { ordinate_fr($_[1]) }

# Note that numf and quant are provided by default.

sub duration {
  my $self = shift;
  my ($seconds) = @_;
  return $self->numf($seconds)." seconds";
}

sub timestamp {
  my $self = shift;
  my ($timestamp) = @_;
  return scalar(gmtime($timestamp));
}

sub date {
  my $self = shift;
  my ($timestamp) = @_;
  return scalar(gmtime($timestamp));
}

sub amount {
  my $self = shift;
  my ($currency,$value) = @_;
  # See e.g. Number::Format's format_price
  return $currency.$self->numf($value);
}


1;
