package CCNQ::HTTPD;

use common::sense;
use Scalar::Util qw/weaken/;
use URI;
use CCNQ::HTTPD::Request;

use base qw/CCNQ::HTTPD::HTTPServer/;

=pod
  This is basically AnyEvent::HTTPD.pm
  However I want to support PUT, GET, and DELETE, but I don't need POST.
=cut

sub new {
   my $this  = shift;
   my $class = ref($this) || $this;
   my $self  = $class->SUPER::new (@_);

   $self->reg_cb (
      connect => sub {
         my ($self, $con) = @_;

         weaken $self;

         $self->{conns}->{$con} = $con->reg_cb (
            request => sub {
               my ($con, $meth, $url, $hdr, $cont) = @_;
               #d# warn "REQUEST: $meth, $url, [$cont] " . join (',', %$hdr) . "\n";

               $url = URI->new ($url);

               if ($meth eq 'GET' or $meth eq 'DELETE') {
                  $cont =
                     CCNQ::HTTPD::HTTPConnection::_parse_urlencoded ($url->query);
               }

               if ($meth eq 'GET' or $meth eq 'PUT' or $meth eq 'DELETE') {

                  weaken $con;

                  $self->handle_app_req (
                     $meth, $url, $hdr, $cont, $con->{host}, $con->{port},
                     sub {
                        $con->response (@_) if $con;
                     });
               } else {
                  $con->response (501, "Not implemented");
               }
            }
         );
      },
      disconnect => sub {
         my ($self, $con) = @_;
         $con->unreg_cb (delete $self->{conns}->{$con});
      }
   );

   $self->{state} ||= {};

   return $self
}

sub handle_app_req {
   my ($self, $meth, $url, $hdr, $cont, $host, $port, $respcb) = @_;

   my $req =
      CCNQ::HTTPD::Request->new (
         httpd   => $self,
         method  => $meth,
         url     => $url,
         hdr     => $hdr,
         parm    => (ref $cont ? $cont : {}),
         content => (ref $cont ? undef : $cont),
         resp    => $respcb,
         host    => $host,
         port    => $port,
      );

   $self->{req_stop} = 0;
   $self->event (request => $req);
   return if $self->{req_stop};

   my @evs;
   my $cururl = '';
   for my $seg ($url->path_segments) {
      $cururl .= $seg;
      push @evs, $cururl;
      $cururl .= '/';
   }

   for my $ev (reverse @evs) {
      $self->event ($ev => $req);
      last if $self->{req_stop};
   }
}

sub stop_request {
   my ($self) = @_;
   $self->{req_stop} = 1;
}

sub run {
   my ($self) = @_;
   $self->{condvar} = AnyEvent->condvar;
   $self->{condvar}->wait;
}

sub stop { $_[0]->{condvar}->broadcast if $_[0]->{condvar} }

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Robin Redeker, all rights reserved.
Copyright 2009 Stephane Alnet.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;