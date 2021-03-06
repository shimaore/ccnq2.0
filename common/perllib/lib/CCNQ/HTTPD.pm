package CCNQ::HTTPD;
use common::sense;
use Scalar::Util qw/weaken/;
use URI;
use AnyEvent::HTTPD::Request;
use AnyEvent::HTTPD::Util;

use CCNQ::HTTPD::HTTPConnection;

use base qw( AnyEvent::HTTPD );

use Logger::Syslog;

sub new {
   my $this  = shift;
   my $class = ref($this) || $this;
   my $self  = $class->SUPER::new (
      connection_class => 'CCNQ::HTTPD::HTTPConnection',
      @_
   );

   $self->reg_cb (
      connect => sub {
         my ($self, $con) = @_;
         debug("CCNQ::HTTPD: Connected");
         weaken $self;

         $self->{conns}->{$con} = $con->reg_cb (
            request => sub {
               my ($con, $meth, $url, $hdr, $cont) = @_;
               #d# warn "REQUEST: $meth, $url, [$cont] " . join (',', %$hdr) . "\n";

               debug("CCNQ::HTTPD: Request");
               $url = URI->new ($url);

               if ($meth eq 'GET' or $meth eq 'DELETE') {
                  $cont = parse_urlencoded ($url->query);
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

         $self->event (client_connected => $con->{host}, $con->{port});
      },
      disconnect => sub {
         my ($self, $con) = @_;
         debug("CCNQ::HTTPD: Disconnected");
         $con->unreg_cb (delete $self->{conns}->{$con});
         $self->event (client_disconnected => $con->{host}, $con->{port});
      },
   );

   $self->{state} ||= {};

   return $self
}

1;
