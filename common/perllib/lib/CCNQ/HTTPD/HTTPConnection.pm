package CCNQ::HTTPD::HTTPConnection;
use common::sense;
use IO::Handle;
use AnyEvent::Handle;
use Object::Event;
use Time::Local;

use AnyEvent::HTTPD::Util;

use Scalar::Util qw/weaken/;
our @ISA = qw/AnyEvent::HTTPD::HTTPConnection/;

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

      if ($line =~ /(\S+) \040 (\S+) \040 HTTP\/(\d+)\.(\d+)/xso) {
         my ($meth, $url, $vm, $vi) = ($1, $2, $3, $4);

         if (not grep { $meth eq $_ } qw/GET PUT DELETE/) {
            $self->error (405, "method not allowed",
                          { Allow => "GET,PUT,DELETE" });
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

1;
