package CCNQ::Invoicing::Counts;
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

use CCNQ::Install;
use CCNQ::AE;

use AnyEvent;
use AnyEvent::CouchDB;

use CCNQ::Provisioning;
use CCNQ::Billing::Rating;

use Logger::Syslog;

=head2 daily_cdr

daily_cdr will create CDRs that represent the number of items in the
provisioning database.

This is used to account for partial billing-period use of a ressource.

=cut

sub daily_cdr {
  my ($date,$group_level) = @_;

  info("daily_cdr($date,$group_level)");

  # $date        is a YYYYMMDD date (today)
  # $group_level should be either 3 or 4
  #    group_level = 3 means only the profile (location,endpoint,number,..) is used.

  # Run the view
  #    group_level = 4 means the "type" is also used.
  my $couch = couch(CCNQ::Provisioning::provisioning_uri);
  my $db = $couch->db(CCNQ::Provisioning::provisioning_db);

  my $cv = AE::cv;

  my $options = {
    group_level  => $group_level,
  };

  my $view = $db->view('report/count',$options);

  $view->cb(sub {
    my $docs = CCNQ::AE::receive_docs(@_);

    for my $r (@$docs) {
      $cv->begin;

      my @key = @{$r->{key}};
      my $count = $r->{value};

      # For each record, generate a CDR
      my $flat_cbef = {
        start_date  => $date,
        start_time  => '000000',
        account     => $key[0],
        account_sub => $key[1],
        event_type  => join('_','daily_count',@key[2..($group_level-1)]),
        count       => $count,
        collecting_node => CCNQ::Install::host_name,
      };

      my $rcv = CCNQ::Billing::Rating::rate_and_save_cbef($flat_cbef);
      $rcv->cb(sub{
        my $rated_cbef = CCNQ::AE::receive($cv);
        $cv->end;
      });
    }
  });

  return $cv;
}

1;
