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

use File::Temp;
use AnyEvent;
use AnyEvent::Util;
use CCNQ::Util;

use JSON;
use MIME::Base64 ();

use Logger::Syslog;

=head1 REQUIREMENTS

This module assumes that the script in contrib/sip-traces/usr/sbin is
running on the target (local) machine. Traces are saved in /var/log/traces
and this module requires mergecap(1), ngrep(1) and a recent version (>= 1.2)
of tshark(1).

=head1 USAGE

=head2 run($params)

Where $params must contain at least one of:

  call_id     to locate by Call-ID
  to_user     to locate by To username
  from_user   to locate by From username

and may contain:

  days_ago    to locate only records generated this number of day ago
              (0 = today)
  dump_packets  if true the output will be a pcap trace
                otherwise the output will be a set of JSON records

=head1 PERFORMANCE

This script locates calls within two hundred megabytes of traces (the default
storage space in the sip-traces capture script) in about one second.

=cut

use constant trace_field_names => [qw(
  frame.time ip.version ip.dsfield.dscp ip.src ip.dst ip.proto udp.srcport udp.dstport
  sip.Call-ID
  sip.Request-Line
    sip.Method sip.r-uri.user sip.r-uri.host sip.r-uri.port
  sip.Status-Line
    sip.Status-Code
  sip.to.user
  sip.from.user
  sip.From
  sip.To
  sip.contact.addr
  sip.User-Agent
)];

use constant traces_base_dir => '/var/log/traces';

use constant bin_sh => '/bin/sh';

use constant trace_max_lines => 50;

sub install {
  my $base_dir = traces_base_dir;
  my $group = 'wireshark';
  my $dumpcap = '/usr/bin/dumpcap';

  CCNQ::Util::execute('groupadd', '-r', $group);

  CCNQ::Util::execute('chgrp','wireshark',$dumpcap);
  CCNQ::Util::execute('chmod','04750',    $dumpcap);

  CCNQ::Util::execute('mkdir','-p',    $base_dir);
  CCNQ::Util::execute('chgrp',$group,  $base_dir);
  CCNQ::Util::execute('chmod','ug+rwx',$base_dir);
  CCNQ::Util::execute('chmod','o-rwx', $base_dir);
  CCNQ::Util::execute('chmod','g+s',   $base_dir);

  crontab_update();
  return;
}

sub crontab_update {
  # XXX
  # This crontab is installed as the user running the installation (root)
  # which is NOT the user that runs the dumpcap and the xmpp_agent.
  my $crontab_line = <<CRON;
SHELL=/bin/bash
PATH=/bin:/usr/bin:/usr/local/bin
20 3 * * *   nice -n 20 /usr/bin/env find /var/log/traces -type f '!' -newermt '3 days ago' -delete
CRON
  my $crontab_file = File::Spec->catfile(CCNQ::CCN,'ccnq2_crontab_traces.crontab');

  CCNQ::Util::print_to($crontab_file,$crontab_line);
  CCNQ::Util::execute(qq(/usr/bin/crontab "${crontab_file}"));
}

sub run {
  my ($params) = @_;

  debug("trace: checking parameters");
  my $dump_packets = $params->{dump_packets} || 0;
  my $call_id      = $params->{call_id};
  my $to_user      = $params->{to_user};
  my $from_user    = $params->{from_user};
  my $days_ago     = $params->{days_ago} || 0;

  die ['Invalid to_user']
    if defined $to_user   && $to_user   !~ /^\d+$/;
  die ['Invalid from_user']
    if defined $from_user && $from_user !~ /^\d+$/;
  # Call-ID: RFC3261 says word [ "@" word ] with 'word' defined as most ASCII printables.
  die ['Invalid call_id']
    if defined $call_id   && $call_id   !~ /^[[:print:]]+$/;
  die ['Invalid days_ago']
    if defined $days_ago  && $days_ago  !~ /^\d{1,5}$/;

  die ['Missing required parameters']
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

    if(defined($days_ago) && $days_ago =~ /^\d+$/) {
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

  my $base_dir = traces_base_dir;

  my $rcv = AE::cv;

  my $script = new File::Temp (UNLINK => 0, SUFFIX => '.sh');

  if($dump_packets) {
    debug("trace: starting pcap dump");

    # Output the subset of packets
    my $script_content = <<SCRIPT;
#!/bin/bash
FIFODIR=`mktemp -d`
FIFO="\$FIFODIR/fifo"
mkfifo "\$FIFO"
(nice mergecap -w - $base_dir/*.pcap | nice ngrep -i -l -q -I - -O "\$FIFO" '$ngrep_filter' >/dev/null) \&
nice tshark -i "\$FIFO" -R '$tshark_filter' -w /dev/stdout
rm "\$FIFO"
rmdir "\$FIFODIR"
SCRIPT
    print $script $script_content;
    close($script);

    debug("script content: $script_content");

    my $content = '';
    my $cv = AnyEvent::Util::run_cmd [ bin_sh, $script ],
      close_all => 1,
      '>' => \$content;

    $cv->cb(sub {
      shift->recv;
      undef $cv;
      unlink $script;
      debug("trace: completed pcap dump");
      $rcv->send({pcap => MIME::Base64::encode($content)});
      undef $content;
    });

  } else {
    debug("trace: starting text dump");

    # Output JSON
    my $fields = join(' ',map { ('-e', $_) } @{trace_field_names()});
    my $script_content = <<SCRIPT;
#!/bin/bash
FIFODIR=`mktemp -d`
FIFO="\$FIFODIR/fifo"
mkfifo "\$FIFO"
(nice mergecap -w - $base_dir/*.pcap | ngrep -i -l -q -I - -O "\$FIFO" '$ngrep_filter' >/dev/null) \&
nice tshark -i "\$FIFO" -R '$tshark_filter' -nltad -T fields $fields
rm "\$FIFO"
rmdir "\$FIFODIR"
SCRIPT
    print $script $script_content;
    close($script);

    debug("script content: $script_content");

    my @content = ();
    # My assumptions about the callback are:
    #   - receives line-by-line
    #   - gets 'undef' at EOF.

    my $cv = AnyEvent::Util::run_cmd [ bin_sh, $script ],
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
        shift @content if $#content > trace_max_lines;
      };

    $cv->cb(sub {
      shift->recv;
      undef $cv;
      unlink $script;
      debug("trace: completed text dump");
      $rcv->send({rows => [@content]});
      undef @content;
    });

  }

  debug("trace: initiating dump");
  return $rcv;
} # run

'CCNQ::Trace';
