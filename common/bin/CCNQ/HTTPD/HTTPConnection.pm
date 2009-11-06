package CCNQ::HTTPD::HTTPConnection;
use common::sense;
use IO::Handle;
use AnyEvent::Handle;
use Object::Event;
use Time::Local;

use Scalar::Util qw/weaken/;
our @ISA = qw/Object::Event/;

=head1 NAME

CCNQ::HTTPD::HTTPConnection - A simple HTTP connection for request and response handling

=head1 DESCRIPTION

This class is a helper class for L<AnyEvent:HTTPD::HTTPServer> and L<CCNQ::HTTPD>,
it handles TCP reading and writing as well as parsing and serializing
http requests.

It has no public interface yet.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub new {
   my $this  = shift;
   my $class = ref($this) || $this;
   my $self  = { @_ };
   bless $self, $class;

   $self->{request_timeout} = 60
      unless defined $self->{request_timeout};

   $self->{hdl} =
      AnyEvent::Handle->new (
         fh       => $self->{fh},
         on_eof   => sub { $self->do_disconnect },
         on_error => sub { $self->do_disconnect ("Error: $!") }
      );

   $self->push_header_line;

   return $self
}

sub error {
   my ($self, $code, $msg, $hdr, $content) = @_;

   if ($code !~ /^(1\d\d|204|304)$/) {
      unless (defined $content) { $content = "$code $msg" }
      $hdr->{'Content-Type'} = 'text/plain';
   }

   $self->response ($code, $msg, $hdr, $content);
}

sub response_done {
   my ($self) = @_;

   $self->{hdl}->on_drain; # clear any drain handlers
   (delete $self->{transfer_cb})->() if $self->{transfer_cb};

   if ($self->{keep_alive}) {
      $self->push_header_line;

   } else {
      $self->{hdl}->on_drain (sub { $self->do_disconnect });
   }
}

our @DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
our @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
our %MoY;
@MoY{@MoY} = (1..12);

# Taken from HTTP::Date module of LWP.
sub _time_to_http_date
{
    my $time = shift;
    $time = time unless defined $time;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);

    sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
       $DoW[$wday],
       $mday, $MoY[$mon], $year + 1900,
       $hour, $min, $sec);
}


sub response {
   my ($self, $code, $msg, $hdr, $content) = @_;
   return unless $self->{hdl};

   my $res = "HTTP/1.0 $code $msg\015\012";
   $hdr->{'Expires'}        = $hdr->{'Date'}
                            = _time_to_http_date time;
   $hdr->{'Cache-Control'}  = "max-age=0";
   $hdr->{'Connection'}     = $self->{keep_alive} ? 'Keep-Alive' : 'close';

   $hdr->{'Content-Length'} = length $content
      if not (defined $hdr->{'Content-Length'}) && not ref $content;

   unless (defined $hdr->{'Content-Length'}) {
      # keep alive with no content length will NOT work.
      delete $self->{keep_alive};
   }

   while (my ($h, $v) = each %$hdr) {
      $res .= "$h: $v\015\012";
   }

   $res .= "\015\012";

   if (ref ($content) eq 'CODE') {
      weaken $self;

      my $chunk_cb = sub {
         my ($chunk) = @_;

         return 0 unless defined ($self) && defined ($self->{hdl});

         delete $self->{transport_polled};

         if (defined ($chunk) && length ($chunk) > 0) {
            $self->{hdl}->push_write ($chunk);

         } else {
            $self->response_done;
         }

         return 1;
      };

      $self->{transfer_cb} = $content;

      $self->{hdl}->on_drain (sub {
         return unless $self;

         if (length $res) {
            my $r = $res;
            undef $res;
            $chunk_cb->($r);

         } elsif (not $self->{transport_polled}) {
            $self->{transport_polled} = 1;
            $self->{transfer_cb}->($chunk_cb) if $self;
         }
      });

   } else {
      $res .= $content;
      $self->{hdl}->push_write ($res);
      $self->response_done;
   }
}

sub _unquote {
   my ($str) = @_;
   if ($str =~ /^"(.*?)"$/) {
      $str = $1;
      my $obo = '';
      while ($str =~ s/^(?:([^"]+)|\\(.))//s) {
        $obo .= $1;
      }
      $str = $obo;
   }
   $str
}

sub decode_part {
   my ($self, $hdr, $cont) = @_;

   $hdr = _parse_headers ($hdr);
   if ($hdr->{'content-disposition'} =~ /form-data|attachment/) {
      my ($dat, @pars) = split /\s*;\s*/, $hdr->{'content-disposition'};
      my @params;

      my %p;

      my @res;

      for my $name_para (@pars) {
         my ($name, $par) = split /\s*=\s*/, $name_para;
         if ($par =~ /^".*"$/) { $par = _unquote ($par) }
         $p{$name} = $par;
      }

      my ($ctype, $bound) = _content_type_boundary ($hdr->{'content-type'});

      if ($ctype eq 'multipart/mixed') {
         my $parts = $self->decode_multipart ($cont, $bound);
         for my $sp (keys %$parts) {
            for (@{$parts->{$sp}}) {
               push @res, [$p{name}, @$_];
            }
         }

      } else {
         push @res, [$p{name}, $cont, $hdr->{'content-type'}, $p{filename}];
      }

      return @res
   }

   ();
}

sub decode_multipart {
   my ($self, $cont, $boundary) = @_;

   my $parts = {};

   while ($cont =~ s/
      ^--\Q$boundary\E             \015?\012
      ((?:[^\015\012]+\015\012)* ) \015?\012
      (.*?)                        \015?\012
      (--\Q$boundary\E (--)?       \015?\012)
      /\3/xs) {
      my ($h, $c, $e) = ($1, $2, $4);

      if (my (@p) = $self->decode_part ($h, $c)) {
         for my $part (@p) {
            push @{$parts->{$part->[0]}}, [$part->[1], $part->[2], $part->[3]];
         }
      }

      last if $e eq '--';
   }

   return $parts;
}

# application/x-www-form-urlencoded  
#
# This is the default content type. Forms submitted with this content type must
# be encoded as follows:
#
#    1. Control names and values are escaped. Space characters are replaced by
#    `+', and then reserved characters are escaped as described in [RFC1738],
#    section 2.2: Non-alphanumeric characters are replaced by `%HH', a percent
#    sign and two hexadecimal digits representing the ASCII code of the
#    character. Line breaks are represented as "CR LF" pairs (i.e., `%0D%0A').
#
#    2. The control names/values are listed in the order they appear in the
#    document. The name is separated from the value by `=' and name/value pairs
#    are separated from each other by `&'.
#

sub _url_unescape {
   my ($val) = @_;
   $val =~ s/\+/\040/g;
   $val =~ s/%([0-9a-fA-F][0-9a-fA-F])/chr (hex ($1))/eg;
   $val
}

sub _parse_urlencoded {
   my ($cont) = @_;
   my (@pars) = split /\&/, $cont;
   $cont = {};

   for (@pars) {
      my ($name, $val) = split /=/, $_;
      $name = _url_unescape ($name);
      $val  = _url_unescape ($val);

      push @{$cont->{$name}}, [$val, ''];
   }
   $cont
}

sub _content_type_boundary {
   my ($ctype) = @_;
   my ($c, @params) = split /\s*[;,]\s*/, $ctype;
   my $bound;
   for (@params) {
      if (/^\s*boundary\s*=\s*(.*?)\s*$/) {
         $bound = _unquote ($1);
      }
   }
   ($c, $bound)
}

sub handle_request {
   my ($self, $method, $uri, $hdr, $cont) = @_;

   $self->{keep_alive} = ($hdr->{connection} =~ /keep-alive/i);

   my ($ctype, $bound) = _content_type_boundary ($hdr->{'content-type'});

   if ($ctype eq 'multipart/form-data') {
      $cont = $self->decode_multipart ($cont, $bound);

   } elsif ($ctype =~ /x-www-form-urlencoded/) {
      $cont = _parse_urlencoded ($cont);
   }

   $self->event (request => $method, $uri, $hdr, $cont);
}

# loosely adopted from AnyEvent::HTTP:
sub _parse_headers {
   my ($header) = @_;
   my $hdr;

   $header =~ y/\015//d;

   while ($header =~ /\G
      ([^:\000-\037]+):
      [\011\040]*
      ( (?: [^\012]+ | \012 [\011\040] )* )
      \012
   /sgcx) {

      $hdr->{lc $1} .= ",$2"
   }

   return undef unless $header =~ /\G$/sgx;

   for (keys %$hdr) {
      substr $hdr->{$_}, 0, 1, '';
      # remove folding:
      $hdr->{$_} =~ s/\012([\011\040])/$1/sg;
   }

   $hdr
}

sub push_header {
   my ($self, $hdl) = @_;

   $self->{hdl}->unshift_read (line =>
      qr{(?<![^\012])\015?\012},
      sub {
         my ($hdl, $data) = @_;
         my $hdr = _parse_headers ($data);

         unless (defined $hdr) {
            $self->error (599 => "garbled headers");
         }

         push @{$self->{last_header}}, $hdr;

         if (defined $hdr->{'content-length'}) {
            $self->{hdl}->unshift_read (chunk => $hdr->{'content-length'}, sub {
               my ($hdl, $data) = @_;
               $self->handle_request (@{$self->{last_header}}, $data);
            });
         } else {
            $self->handle_request (@{$self->{last_header}});
         }
      }
   );
}

sub push_header_line {
   my ($self) = @_;

   weaken $self;

   $self->{req_timeout} =
      AnyEvent->timer (after => $self->{request_timeout}, cb => sub {
         return unless defined $self;

         $self->do_disconnect ("request timeout ($self->{request_timeout})");
      });

   $self->{hdl}->push_read (line => sub {
      my ($hdl, $line) = @_;
      return unless defined $self;

      delete $self->{req_timeout};

      if ($line =~ /(\S+) \040 (\S+) \040 HTTP\/(\d+)\.(\d+)/xs) {
         my ($meth, $url, $vm, $vi) = ($1, $2, $3, $4);

         if (not grep { $meth eq $_ } qw/GET HEAD POST/) {
            $self->error (405, "method not allowed",
                          { Allow => "GET,HEAD,POST" });
            return;
         }

         if ($vm >= 2) {
            $self->error (506, "http protocol version not supported");
            return;
         }

         $self->{last_header} = [$meth, $url];
         $self->push_header;

      } elsif ($line eq '') {
         # ignore empty lines before requests, this prevents
         # browser bugs w.r.t. keep-alive (according to marc lehmann).
         $self->push_header_line;

      } else {
         $self->error (400 => 'bad request');
      }
   });
}

sub do_disconnect {
   my ($self, $err) = @_;

   $self->{transfer_cb}->() if $self->{transfer_cb};
   delete $self->{transfer_cb};
   delete $self->{req_timeout};
   $self->event ('disconnect', $err);
   delete $self->{hdl};
}

1;
