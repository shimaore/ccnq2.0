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
use strict; use warnings;

use base qw( Locale::Maketext );
use File::ShareDir;
use File::Spec;

use constant CCNQ_PORTAL_MAKEFILE_MODULE_NAME => 'CCNQ-Portal';
use constant i18n_base => File::ShareDir::dist_dir(CCNQ_PORTAL_MAKEFILE_MODULE_NAME);

use constant i18n_directory => File::Spec->catfile(i18n_base,qw( i18n ));
use constant portal_po_file => 'portal.po';
sub i18n_gettext_location {
  return File::Spec->catfile(i18n_directory,$_[0],portal_po_file);
}

# See http://cpansearch.perl.org/src/DRTECH/Locale-Maketext-Lexicon-0.77/docs/webl10n.html

use Locale::Maketext::Lexicon {
        'en' => [Gettext => i18n_gettext_location('en')],
        'fr' => [Gettext => i18n_gettext_location('fr')],
        'fr_fr' => [Gettext => i18n_gettext_location('fr')],
        ### Uncomment to decode lexicon entries into Unicode strings
        _decode => 1,
        ### Uncomment to fallback when a key is missing from lexicons
        _auto   => 1,
        ### Uncomment to use %1 / %quant(%1) instead of [_1] / [quant, _1]
        # _style  => 'gettext',
};

sub encoding {
  return 'utf-8';
}

sub duration {
  my $self = shift;
  my ($seconds) = @_;
  my $hours = int($seconds / 3600);
  $seconds -= $hours*3600;
  my $minutes = int($seconds / 60);
  $seconds -= $minutes*60;

  my @text = ();
  $hours   and push @text, "${hours}h";
  $minutes and push @text, "${minutes}m";
  push @text, "${seconds}s";
  return join(' ',@text);
}

# These follow DateTime conventions.
sub time {
  my $self = shift;
  my ($time) = @_;
  return $time->hms;
}

# See also Data::Money, Locale::Currency, etc.
sub currencies {
  return {
    'EUR' => "\x{20AC}",
    'USD' => 'US$',
  };
}


package CCNQ::I18N::en;

use base qw(CCNQ::I18N);

use Lingua::EN::Numbers::Ordinate;
sub ord { ordinate($_[1]) }

# Note that numf and quant are provided by default.

# These follow DateTime conventions.

sub date {
  my $self = shift;
  my ($date) = @_;
  return $date->mdy('/');
}

sub amount {
  my $self = shift;
  my ($value,$currency) = @_;
  $currency ||= '';
  # See e.g. Number::Format's format_price
  return $currency.$self->numf($value);
}


package CCNQ::I18N::fr;

use base qw(CCNQ::I18N);

use Lingua::FR::Numbers qw(number_to_fr ordinate_to_fr);
sub numb{ number_to_fr($_[1]) }
sub ord { ordinate_to_fr($_[1]) }
#use Lingua::FR::Numbers::Ordinate;
#sub fr::ord { ordinate_fr($_[1]) }

# These follow DateTime conventions.

sub date {
  my $self = shift;
  my ($date) = @_;
  return $date->dmy('/');
}

sub amount {
  my $self = shift;
  my ($value,$currency) = @_;
  $currency ||= '';
  # See e.g. Number::Format's format_price
  return $self->numf($value)." ".$currency;
}

'CCNQ::I18N';
