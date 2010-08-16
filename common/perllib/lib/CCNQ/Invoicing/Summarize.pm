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

use DateTime;
use DateTime::Duration;

use AnyEvent;
use AnyEvent::CouchDB;

use CCNQ::CDR;

use Logger::Syslog;

sub compute {
  my ($view,$account,$start_dt,$end_dt) = @_;

  my $duration = $end_dt - $start_dt;
  my $days = $duration->in_units('days');
  debug("This period had $days days.");

  my $by_event = CCNQ::MathContainer->new;
  my $by_sub   = CCNQ::MathContainer->new;
  my $summary  = CCNQ::Invoicing::Record->new;

  my $counts   = {};

  my $cv = AE::cv;
  $cv->begin;

  # Add each CDR per-category
  my $add_cdr = sub {
    my ($cbef) = @_;

    use bignum;

    # Add each CDR per category.
    my $account_sub = $cbef->{account_sub};
    my $event_type  = $cbef->{event_type};
    if($event_type =~ /^daily_count_(.*)$/) {
      my $type = $1;
      $counts->{$account_sub}->{$type} += $cbef->{count};
    } else {
      $by_event->{$account_sub}->{$event_type} ||=
        CCNQ::Invoicing::Record->new;
      $by_sub->{$account_sub} ||=
        CCNQ::Invoicing::Record->new;

      $by_event->{$account_sub}->{$event_type}->add_cdr($cbef);
      $by_sub  ->{$account_sub}                 ->add_cdr($cbef);
      $summary                                    ->add_cdr($cbef);
    }
  };

  # Create new CDRs for the daily counts
  my $compute_counts = sub {

    while( my ($account_sub,$r) = each %$counts ) {

      while( my ($type,$count) = each %$r ) {

        # Create CDR for the total of the monthly counts.
        my $units = $count / $days;

        my $flat_cbef = CCNQ::Rating::Event->new({
          start_date  => $start_dt->ymd(''),
          start_time  => '000000',
          account     => $account,
          account_sub => $account_sub,
          event_type  => 'count_'.$type,
          count       => $units,

          collecting_node => CCNQ::Install::host_name,
        });

        my $cv = CCNQ::Billing::Rating::rate_and_save_cbef($flat_cbef);
        my $cbef = CCNQ::AE::receive($cv);

        $add_cdr->($cbef);

      }
    }
  };

  $view->cb(sub {
    my $docs = CCNQ::AE::receive_docs(@_);

    # Count daily events, and accumulate other CDRs.
    for my $cbef (@$docs) {
      $add_cdr->($cbef);
    }

    # Rating for daily counts
    $compute_counts->();

    # Store the resulting data in the "invoicing" database.

    my $id = join('/',$account,$start_dt->year,$start_dt->month);

    my $data = {
      _id     => $id,
      account => $account,

      # The date at which the invoice was generated. (Bill date)
      billed  => $end_dt->ymd(''),

      # The period for which the invoice was generated. (Start date)
      year    => $start_dt->year,
      month   => $start_dt->month,
      day     => $start_dt->day,

      # Number of days in the billing period.
      days    => $days,

      summary => $summary ->cleanup,
      by_sub  => $by_sub  ->cleanup,
      by_event=> $by_event->cleanup,
      # More details: use the CDRs themselves.
    };

    CCNQ::Invoicing::insert($data)->cb(sub {
      CCNQ::AE::Receive(@_);
      $cv->end;
    });
  });

  return $cv;
}

sub monthly {
  my ($account_billing_data,$end_dt) = @_;

  # Select all the CDRs that have been created since the last bill run.
  my $account = $account_billing_data->{account};

  # Last month, same day of the month.
  my $every = DateTime::Duration->new( months => 1 );
  my $start_dt = $end_dt - $every;

  my $couch = couch(CCNQ::CDR::cdr_uri);
  my $db = $couch->db(CCNQ::CDR::cdr_db);

  my $options = {
    startkey     => [$account,$start_dt->ymd('')],
    endkey       => [$account,$end_dt  ->ymd('')],
    include_docs => "true",
  };

  my $view = $db->view('report/invoicing',$options);
  return compute($view,$account,$start_dt,$end_dt);
}

1;
