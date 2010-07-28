package CCNQ::Invoicing::Summarize;
# Copyright (C) 2010  Stephane Alnet
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

use AnyEvent;
use AnyEvent::CouchDB;

use CCNQ::CDR;

sub compute {
  my ($view,$account,$bill_cycle,$year,$month,$end_date) = @_;

  my $by_event = CCNQ::Invoicing::Record->new;
  my $by_sub   = CCNQ::Invoicing::Record->new;
  my $summary  = CCNQ::Invoicing::Record->new;

  $view->cb(sub {
    my $r = CCNQ::AE::receive(@_);
    my $cbef = $r->{doc};
    # Add each CDR per-category.
    my $account_sub = $cbef->{account_sub};
    my $event_type  = $cbef->{event_type};
    $by_event->{$account_sub}->{$event_type} = add_cdr(
      $by_event->{$account_sub}->{$event_type} || {},
      $cbef,
    );
    $by_sub->{$account_sub} = add_cdr(
      $by_sub->{$account_sub} || {},
      $cbef,
    );
    $summary = add_cdr( $summary, $cbef );
  });

  # Store the resulting data in the "invoices" database.

  my $id = join('/',$account,$end_date);

  my $data = {
    _id     => $id,
    account => $account,
    # The date at which the invoice was generated. (Bill date)
    billed  => $end_date,
    # The period for which the invoice was generated. (Start date)
    year    => $year,
    month   => $month,
    day     => $bill_cycle,
    summary => $summary->cleanup,
    by_sub  => $by_sub->cleanup,
    by_event=> $by_event->cleanup,
    # More details: use the CDRs themselves.
  };

  CCNQ::Invoicing::insert($data)->cb(sub {
    CCNQ::AE::Receive(@_);
  });
  return;
}

sub monthly {
  my ($account_billing_data,$bill_cycle,$year,$month) = @_;

  # Include top-of-bill information

  my $account = $account_billing_data->{account};

  # Select all the CDRs that have been created since the last bill run.
  # This means: CDR from (year,month-1,bill_cycle) until yesterday.

  my $end_date   = sprintf('%04d%02d%02d',$year,$month,$bill_cycle);
  # Last month, same day of the month.
  $month --;
  $month > 0 or ($month,$year) = (12,$year-1);
  my $start_date = sprintf('%04d%02d%02d',$year,$month,$bill_cycle);

  my $couch = couch(CCNQ::CDR::cdr_uri);
  my $db = $couch->db(CCNQ::CDR::cdr_db);

  my $options = {
    startkey     => [$account,$start_date],
    endkey       => [$account,$end_date],
    include_docs => "true",
  };

  my $view = $db->view('invoicing',$options);
  compute($view,$account,$bill_cycle,$year,$month,$end_date);
}

1;
