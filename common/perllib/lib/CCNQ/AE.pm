package CCNQ::AE;
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
use AnyEvent;
use AnyEvent::Util;
use Logger::Syslog;

# Non-blocking version
sub execute {
  my $context = shift;
  my $command = join(' ',@_);

  my $rcv = AE::cv;

  my $cv = eval { AnyEvent::Util::run_cmd([@_],'<','/dev/null','>','/dev/null','2>','/dev/null') };
  die ['Failed to execute [_1]: [_2]',$@] if $@;
  $cv->cb( sub {
    my $ret = eval { shift->recv };

    return $rcv->send(['Failed to execute [_1]: [_2]',$command,$@]) if $@;

    return $rcv->send('completed') if $ret == 0;

    # Happily lifted from perlfunc.
    if ($ret == -1) {
        return $rcv->send(['Failed to execute [_1]: [_2]',$command,$!]);
    }
    elsif ($ret & 127) {
        return $rcv->send(['Child command [_1] died with signal [_2], [_3] coredump',
            $command, ($ret & 127),  ($ret & 128) ? 'with' : 'without' ]);
    }
    else {
        return $rcv->send(['Child command [_1] exited with value [_2]',
          $command, $ret >> 8 ]);
    }
  });
  return $rcv;
}

use Encode;
use Scalar::Util qw(blessed);

sub pp {
  my $v = shift;
  return qq(nil)  if !defined($v);
  return encode_utf8(blessed($v).":".qq("$v")) if blessed($v);
  return encode_utf8(qq("$v")) if !ref($v);
  return '[ '.join(', ', map { pp($_) } @{$v}).' ]'
    if UNIVERSAL::isa($v,'ARRAY');
  return '{ '.join(', ', map { pp($_).q(: ).pp($v->{$_}) } sort keys %{$v}).' }'
    if UNIVERSAL::isa($v,'HASH');
  return encode_utf8(qq("???:$v"));
}

sub ppp {
  return join(',', map { pp($_) } @_);
}

our $debug_receive = 1;

sub receive {
  my $result;
  eval { $result = $_[0]->recv };
  if($@) {
    debug("Callback failed: ".pp($@).", with result: ".pp($result)) if $debug_receive;
    return undef;
  }

  debug("Callback received: ".pp($result)) if $debug_receive;
  return $result;
}

sub receive_rows {
  return receive(@_) || { rows => [] };
}

sub receive_docs {
  return [ map { $_->{doc} } @{receive_rows(@_)->{rows}} ];
}

sub receive_ids {
  return [ map { $_->{id} } @{receive_rows(@_)->{rows}} ];
}

sub receive_first_doc {
  return receive_rows(@_)->{rows}->[0]->{doc};
}

sub croak_cv {
  my $cv = AE::cv;
  $cv->croak(@_);
  return $cv;
}

'CCNQ::AE';
