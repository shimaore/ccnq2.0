package CCNQ::Invoice;
=head1 NAME
  Invoice base for ccnq2.0

=head1 AUTHOR
  Stephane Alnet <stephane@shimaore.net>

=head1 LICENSE
Copyright (C) 2010  Stephane Alnet

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

use 5.008;

our $VERSION = '0.054';

use strict; use warnings;

=head1 SUMMARY

The CCNQ::Invoice code provides a basis for invoice generation.
It knows how to get data from the backends (through the API) and can
generate summaries, etc.

However the layout is not fixed and this code will attempt to provide
flexibility.

=head1 SYNOPSIS


  use CCNQ::Invoice::PDF;

  my $generator = CCNQ::Invoice::PDF->new({
    account=>"stephane",
    year=>2010,
    month=>7,
    locale=>"fr"
  });

  # Print out the PDF
  print $generator->run();

=cut

use base qw(CCNQ::Object);

=head1 new(\%opts)

%opts must contain:

  account
  year
  month
  locale

=cut

use CCNQ::Locale;

sub locale  {
  my $self = shift;
  if(!$self->{_locale}) {
    $self->{_locale} = CCNQ::Locale->new($self->{locale});
  }
  return $self->{_locale};
}

sub loc     { shift->locale->loc(@_) }

sub account { shift->{account} }

# Period start-date
sub year    { shift->{year}    }
sub month   { shift->{month}   }
sub day     { shift->invoice->{day} }

=head2 billed

Billed date (YYYYMMDD)

=cut

sub billed  { shift->invoice->{billed} }
sub days    { shift->invoice->{days}   }

sub summary { shift->invoice->{summary}  }
sub by_sub  { shift->invoice->{by_sub}   }
sub by_event{ shift->invoice->{by_event} }

use CCNQ::API;

sub account_data {
  my $self = shift;

  if(!$self->{account_data}) {
    my $cv = AE::cv;
    CCNQ::API::billing('report','accounts',$self->account,$cv);
    $self->{account_data} = CCNQ::AE::receive_first_doc($cv);
  }
  return $self->{account_data} or die "account_data not available";
}

sub account_subs {
  my $self = shift;

  if(!$self->{account_subs}) {
    my $cv = AE::cv;
    CCNQ::API::billing('report','account_subs',$self->account,$cv);
    $self->{account_subs} = CCNQ::AE::receive_docs($cv);
  }
  return $self->{account_subs} or die "account_subs not available";
}

sub invoice {
  my $self = shift;
  if(!$self->{invoice}) {
    my $cv = AE::cv;
    CCNQ::API::invoicing('report','monthly',$self->account,$self->year,$self->month,$cv);
    $self->{invoice} = CCNQ::AE::receive_first_doc($cv);
  }
  return $self->{invoice} or die "invoice not available";
}

sub cdr_by_sub {
  my $self = shift;
  my ($account_sub) = @_;

  my $cv = AE::cv;
  CCNQ::API::cdr('report','monthly_by_sub',$self->account,$self->year,$self->month,$account_sub,$cv);
  return CCNQ::AE::receive_docs($cv);
}

sub run {
  my $self = shift;

  $self->header1($self->loc('Your invoice'));

  $self->do_summary();

  $self->do_account_subs();

  $self->do_detail();
  return $self->as_string;
}

sub do_account_subs {
  my $self = shift;

  my $account_subs = $self->account_subs;
  my $by_sub        = $self->by_sub;
  my $by_event      = $self->by_event;

  for my $r (@$account_subs) {
    my $account_sub = $r->{account_sub};

    # Show summary for this sub
    $self->header2($r->{name});
    if( $by_sub->{$account_sub} ) {
      $self->monetary_record($by_sub->{$account_sub});
    }

    # Show per-event-type summary for this sub
    $by_event->{$account_sub}
      or next;

    for my $ev (sort keys %{$by_event->{$account_sub}}) {
      # Restrict to the higher levels for now -- we probably don't have
      # translations for the lower ones.
      next unless $ev =~ /^[^_]+_[^_]+$/; # count_*, *_call, ..
      $self->summary_record($by_event->{$account_sub}->{$ev},$self->loc($ev||'days'));
    }
  }
}

sub do_detail {
  my $self = shift;

  my $account_subs = $self->account_subs;
  my $by_sub        = $self->by_sub;

  for my $r (@$account_subs) {
    my $account_sub = $r->{account_sub};

    # Show details for this sub
    $self->header2($r->{name},$self->loc('CDR'));
    $self->start_records;
    my $cdrs = $self->cdr_by_sub($account_sub);
    for my $cdr (@$cdrs) {
      $self->cdr_line($cdr);
    }
    $by_sub->{$account_sub}
      and $self->summary_line($by_sub->{$account_sub});
    $self->stop_records;
  }
}

sub do_summary {
  my $self = shift;

  $self->header2($self->loc('Invoice Summary'));
  $self->monetary_record($self->summary);
}

1;
