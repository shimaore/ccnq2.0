package CCNQ::Trace;
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

# We assume you are running the contrib/traces.sh script
# This script will locate records that pertain to a specific to / from
# combination and return a report.

# NOTE: Requires tshark 1.2 or above. (e.g. tshark/testing if using Lenny)

# This script assumes you have contrib/traces.sh running, and will use
# the PCAP files in /var/log/traces to find trace information about
# past calls.

use strict; use warnings;

use CCNQ::Install;
use File::Temp;
use AnyEvent::Util;

use JSON;

use Logger::Syslog;

use constant trace_field_names => [qw(
  frame.time ip.version ip.dsfield.dscp ip.src ip.dst ip.proto udp.srcport udp.dstport
  sip.Call-ID
  sip.Request-Line
    sip.Method sip.r-uri.user sip.r-uri.host sip.r-uri.port
  sip.Status-Line
    sip.Status-Code
  sip.to.addr
  sip.from.addr
  sip.contact.addr
  sip.From
  sip.To
  sip.User-Agent
)];

use constant bin_sh => '/bin/sh';

sub run {
  my ($params,$context,$mcv) = @_;

  debug("trace: checking parameters");
  my $dump_packets = $params->{params}->{dump_packets} || 0;
  my $call_id      = $params->{params}->{call_id};
  my $to_user      = $params->{params}->{to_user};
  my $from_user    = $params->{params}->{from_user};
  my $days_ago     = $params->{params}->{days_ago} || 0;

  $mcv->send(CCNQ::Install::FAILURE('Invalid to_user')  ), return
    if defined $to_user   && $to_user   !~ /^\d+$/;
  $mcv->send(CCNQ::Install::FAILURE('Invalid from_user')), return
    if defined $from_user && $from_user !~ /^\d+$/;
  $mcv->send(CCNQ::Install::FAILURE('Invalid call_id')  ), return
    if defined $call_id   && $call_id   !~ /^[\w@-]+$/;
  $mcv->send(CCNQ::Install::FAILURE('Invalid days_ago') ), return
    if defined $days_ago  && $days_ago  !~ /^\d{1,5}$/;

  $mcv->send(CCNQ::Install::FAILURE('Missing required parameters')), return
    unless defined $call_id or defined $to_user or defined $from_user;

  #### Generate a merged capture file #####
  debug("trace: creating filters");

  my $make_ngrep_filter = sub {
    my @ngrep_filter = ();
    push @ngrep_filter, 'To'.     ':[^\r\n]*'.$to_user   if defined $to_user;
    push @ngrep_filter, 'From'.   ':[^\r\n]*'.$from_user if defined $from_user;
    push @ngrep_filter, 'Call-ID'.':[^\r\n]*'.$call_id   if defined $call_id;
    return join('|',@ngrep_filter);
  };

  my $ngrep_filter = $make_ngrep_filter->();

  my $make_tshark_filter = sub {
    my @tshark_filter = ();

    if(defined $days_ago) {
      # Wireshark's format: Nov 12, 1999 08:55:44.123
      sub make_day {
        my $t = shift;
        my @t = localtime($t);
        return ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']->[$t[4]].
               ' '.
               $t[3].
               ', '.
               sprintf('%04d',$t[5]+1900).
               ' 00:00:00.000';
      }

      my $today = make_day(time-86400*$days_ago);
      push @tshark_filter, qq(frame.time >= "$today");
      my $tomorrow = make_day(time-86400*($days_ago-1));
      push @tshark_filter, qq(frame.time < "$tomorrow");
    }

    push @tshark_filter, qq(sip.r-uri.user contains "$to_user" || sip.to.user contains "$to_user") if defined $to_user;
    push @tshark_filter, qq(sip.from.user contains "$from_user") if defined $from_user;
    push @tshark_filter, qq(sip.Call-ID == "$call_id") if defined $call_id;
    return join(' && ', map { "($_)" } @tshark_filter);
  };

  my $tshark_filter = $make_tshark_filter->();

  my $base_dir = '/var/log/traces';

  my $cv;

  my $fh     = new File::Temp (SUFFIX => '.pcap');
  my $script = new File::Temp (UNLINK => 0, SUFFIX => '.sh');

  if($dump_packets) {
    debug("trace: starting pcap dump");

    # Output the subset of packets
    print $script <<SCRIPT;
#!/bin/sh
mergecap -w - $base_dir/*.pcap | ngrep -i -l -q -I - -O '$fh' '$ngrep_filter' >/dev/null;
exec tshark -r "$fh" -R '$tshark_filter' -w -
SCRIPT
    close($script);

    my $content = '';
    $cv = AnyEvent::Util::run_cmd [ bin_sh, $script ],
      close_all => 1,
      '>' => \$content;

    $cv->cb(sub {
      shift->recv;
      undef $cv;
      undef $fh;
      unlink $script;
      debug("trace: completed pcap dump");
      $mcv->send(CCNQ::Install::SUCCESS({pcap => [$content]}));
    });

  } else {
    debug("trace: starting text dump");

    # Output JSON
    my $fields = join(' ',map { ('-e', $_) } @{trace_field_names()});
    print $script <<SCRIPT;
#!/bin/sh
mergecap -w - $base_dir/*.pcap | ngrep -i -l -q -I - -O '$fh' '$ngrep_filter' >/dev/null;
exec tshark -r "$fh" -R '$tshark_filter' -nltad -T fields $fields
SCRIPT
    close($script);

    my @content = ();
    # My assumptions about the callback are:
    #   - receives line-by-line
    #   - gets 'undef' at EOF.

    $cv = AnyEvent::Util::run_cmd [ bin_sh, $script ],
      close_all => 1,
      '<' => '/dev/null',
      '2>' => '/dev/null',
      '>' => sub {
        my $t = shift;
        debug("trace: reading text dump: $t");
        if(!defined $t) {
          return;
        }
        chomp $t;
        my @values = split(/\t/,$t);
        my %values = ();
        for my $i (0..$#values) {
          my $value = $values[$i];
          next unless defined $value && $value ne '';
          $value =~ s/\\"/"/g; # tshark escapes " into \"
          $values{trace_field_names()->[$i]} = $value;
        }
        push @content, {%values};
      };

    $cv->cb(sub {
      shift->recv;
      undef $cv;
      undef $fh;
      unlink $script;
      debug("trace: completed text dump");
      $mcv->send(CCNQ::Install::SUCCESS({rows => [@content]}));
    });

  }

  debug("trace: initiating dump");
  $context->{condvar}->cb($cv);
  debug("trace: end");
} # run

1;

__END__

  if($dump_packets) {
    debug("trace: starting pcap dump");

    # Output the subset of packets
    print $script <<SCRIPT;
#!/bin/sh
mergecap -w - $base_dir/*.pcap | ngrep -i -l -q -I - -O '$fh' '$ngrep_filter' >/dev/null;
exec tshark -r "$fh" -R '$tshark_filter' -w -
SCRIPT
    close($script);

    if(!open(my $fh,'-|', bin_sh, $script )) {
      error($!);
      unlink $script;
      $mcv->send(CCNQ::Install::FAILURE($!));
      return;
    };
    my $content = '';
    local $/;
    $content = <$fh>;
    if(!close($fh)) {
      error($!);
      unlink $script;
      $mcv->send(CCNQ::Install::FAILURE($!));
      return;
    };

    unlink $script;
    debug("trace: completed pcap dump");
    $mcv->send(CCNQ::Install::SUCCESS({pcap => [$content]}));
  } else {
    debug("trace: starting text dump");

    # Output JSON
    my $fields = join(' ',map { ('-e', $_) } @{trace_field_names()});
    print $script <<SCRIPT;
#!/bin/sh
mergecap -w - $base_dir/*.pcap | ngrep -i -l -q -I - -O '$fh' '$ngrep_filter' >/dev/null;
exec tshark -r "$fh" -R '$tshark_filter' -nltad -T fields $fields
SCRIPT
    close($script);

    if(!open(my $fh,'-|', bin_sh, $script )) {
      error($!);
      unlink $script;
      $mcv->send(CCNQ::Install::FAILURE($!));
      return;
    };
    my @content = ();
    while(<$fh>) {
      chomp;
      my @values = split(/\t/);
      my %values = ();
      for my $i (0..$#values) {
        my $value = $values[$i];
        next unless defined $value && $value ne '';
        $value =~ s/\\"/"/g; # tshark escapes " into \"
        $values{trace_field_names()->[$i]} = $value;
      }
      push @content, {%values};
    }
    if(!close($fh)) {
      error($!);
      unlink $script;
      $mcv->send(CCNQ::Install::FAILURE($!));
      return;
    };

    unlink $script;
    debug("trace: completed text dump");
    $mcv->send(CCNQ::Install::SUCCESS({rows => [@content]}));
  }
}
