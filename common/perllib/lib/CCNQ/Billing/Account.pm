package CCNQ::Billing::Account;
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

sub _account_id {
  return join('/','account',@_);
}

sub _account_sub_id {
  return join('/','account_sub',@_);
}


use CCNQ::Billing;
use CCNQ::Billing::Plan;

=head1 Content of an "account" record

An account record must contain at least:

  account: this account's ID
  name: this account's name
  billing_country: this account's billing country
  billing_address: other elements of the account's billing address (as provided by Geo::PostalAddress)
  billing_cycle: the day (in month) where invoices are created for this account (for monthly billing cycles)

=cut

=head1 update_account({ account => $account, ... })

Returns a condvar.

=cut

sub update_account {
  my ($params) = @_;
  return CCNQ::Billing::billing_update({
    %$params,
    profile => 'account',
    _id     => _account_id($params->{account}),
  });
}

=head1 retrieve_account({ account => $account })

Returns a condvar which will return undef or a hashref describing an account.

=cut

sub retrieve_account {
  my ($params) = @_;
  return CCNQ::Billing::billing_retrieve({
    _id => _account_id($params->{account})
  });
}

=head1 Content of an "account_sub" record

An account_sub record must contain at least:

  account: the parent account number
  account_sub: this account_sub's ID
  name: this account_sub's name
  plan: the name of the plan to be used to bill for this account_sub

=cut

=head1 update_account_sub({ account => $account, account_sub => $account_sub, plan => $plan_name, ... })

Returns a condvar.

=cut

sub update_account_sub {
  my ($params) = @_;
  return CCNQ::Billing::billing_update({
    %$params,
    profile => 'account_sub',
    _id     => _account_sub_id($params->{account},$params->{account_sub}),
  });
}

=head1 retrieve_account_sub({ account => $account, account_sub => $account_sub})

Returns a condvar which will return undef or a hashref describing an account_sub.

=cut

sub retrieve_account_sub {
  my ($params) = @_;
  return CCNQ::Billing::billing_retrieve({
    _id => _account_sub_id($params->{account},$params->{account_sub})
  });
}

=head1 plan_of({ account => $account, account_sub => $account_sub })

Returns a condvar which will return either undef or a valid CCNQ::Rating::Plan object.

=cut

use AnyEvent;
use CCNQ::AE;
use Logger::Syslog;

sub plan_of {
  my ($params) = @_;
  my $rcv = AE::cv;
  retrieve_account_sub($params)->cb(sub{
    my $rec = CCNQ::AE::receive(@_);
    if($rec && $rec->{plan}) {
      debug("CCNQ::Billing::Account received plan name $rec->{plan}");
      CCNQ::Billing::Plan::retrieve_plan_by_name($rec->{plan})->cb(sub{
        $rcv->send(CCNQ::AE::receive(@_));
      })
    } else {
      debug("CCNQ::Billing::Account received no plan name");
      $rcv->send;
    }
  });
  return $rcv;
}

'CCNQ::Billing::Account';
