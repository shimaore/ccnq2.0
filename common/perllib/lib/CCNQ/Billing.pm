package CCNQ::Billing;
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

use CCNQ::CouchDB;
use CCNQ::AE;

use constant billing_uri => undef;
use constant billing_db => 'cdr';

use constant billing_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};

sub install {
  return CCNQ::CouchDB::install(billing_uri,billing_db,billing_designs);
}

sub update {
  my ($params) = @_;
  return CCNQ::CouchDB::update_cv(billing_uri,billing_db,$params);
}

sub delete {
  my ($params) = @_;
  return CCNQ::CouchDB::delete_cv(billing_uri,billing_db,$params);
}

sub retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(billing_uri,billing_db,$params);
}

sub view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(billing_uri,billing_db,$params);
}


=head1 rate_and_save_cbef

Save a flat (non-rated) CBEF.

This is used for example to create billable events off the provisioning system.

=cut

use AnyEvent;
use CCNQ::Rating;
use CCNQ::Rating::Event;

sub rate_cbef {
  my ($cbef) = @_;
  my $rcv = AE::cv;
  lookup_plan($cbef->account,$cbef->account_sub)->cb(sub{
    my $plan = CCNQ::AE::receive(@_);
    if($plan) {
      CCNQ::Rating::rate_cbef($cbef,$plan)->cb($rcv);
    } else {
      $rcv->send;
    }
  });
  return $rcv;
}

sub rate_and_save_cbef {
  my ($cbef) = @_;
  my $rcv = AE::cv;
  rate_cbef($cbef)->cb(sub{
    my $rated_cbef = CCNQ::AE::receive(@_);
    $rcv->send('Rating failed') if !$rated_cbef;

    $rated_cbef->compute_taxes();

    # Save the new (rated) CBEF...
    CCNQ::CDR::insert($rated_cbef)->cb($rcv);
  });
  return $rcv;
}

use AnyEvent::CouchDB;
use CCNQ::CouchDB;

sub lookup_plan {
  my ($account,$sub_account) = @_;
  my $id = join('/','sub_account',$account,$sub_account);
  my $rcv = AE::cv;
  couchdb(billing_db)->open_doc($id)->cb(sub{
    my $rec = CCNQ::AE::receive(@_);
    if($rec && $rec->{plan}) {
      load_plan($rec->{plan})->cb(sub{
        $rcv->send(eval {shift->recv});
      })
    } else {
      $rcv->send;
    }
  });
  return $rcv;
}

sub load_plan {
  my ($plan) = @_;
  my $id = join('/','plan',$plan);
  my $rcv = AE::cv;
  couchdb(billing_db)->open_doc($id)->cb(sub{
    my $rec = CCNQ::AE::receive(@_);
    $rcv->send(CCNQ::Rating::Plan->new($rec)) if $rec;
  });
  return $rcv;
}

'CCNQ::Billing';
