package CCNQ::Portal::Outer::AccountSelection;
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

use Dancer ':syntax';
use CCNQ::Portal;

=pod

  CCNQ::Portal::Outer::AccountSelection
    Allows the user to select the "current account" they are working
    with inside the portal.

=cut

sub available_accounts {
  if(CCNQ::Portal->current_session->user) {
    return CCNQ::Portal->current_session->user->profile->portal_accounts || [];
  } else {
    return [];
  }
}

sub account {
  my $account = shift;
  my $accounts = available_accounts;

  # "is_admin" profiles can access any account.
  if(CCNQ::Portal->current_session->user->profile->is_admin) {
    defined $account or $account = '';
    # However they might copy and paste account IDs with extraneous spaces.
    $account =~ s/^\s+//;
    $account =~ s/\s+$//;
    session account => $account;
    return session('account');
  }

  if($#{$accounts} == -1) {
    # Account selection is not possible, the user does not have access to any account
    session account => undef;
  } elsif($#{$accounts} == 0) {
    # Only one account is available, no need to "select" this one -- enforce it.
    session account => $accounts->[0];
  } elsif($#{$accounts} > 0) {
    if(defined($account)) {
      session account => $account
        if defined $accounts
        && grep { $_ eq $account } @{$accounts};
    } else {
      session account => $accounts->[0];
    }
  }
  return session('account');
}

post '/account' => sub {
  my $account = params->{account};
  account($account);
  CCNQ::Portal::content;
};

post '/account/:account' => sub {
  my $account = params->{account};
  account($account);
};

'CCNQ::Portal::Outer::AccountSelection';
