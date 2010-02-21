package CCNQ::Portal::Locale;
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

=pod

  new CCNQ::Portal::User $user_id

=cut

sub new {
    my $this = shift; my $class = ref($this) || $this;
    my $self = { _locale => $_[0] };
    return bless $self, $class;
}

sub id { $self->{_locale} }

sub lang {
  my $self = shift;
  $self->{_lang} ||= CCNQ::I18N->get_handle($self->current_locale);
}

sub loc {
  my $self = shift;
  $self->lang->maketext(@_);
}

sub loc_duration {}

sub loc_timestamp {}

sub loc_date {}

sub loc_amount {
  my $self = shift;
  my ($currency,$value) = @_;
}

'CCNQ::Portal::Locale';
