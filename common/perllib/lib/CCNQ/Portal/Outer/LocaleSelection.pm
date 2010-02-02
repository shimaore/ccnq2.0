package CCNQ::Portal::Outer::UserAuthentication;

use CCNQ::Portal::Outer::Widget qw(if_ok);

use Dancer ':syntax';
use CCNQ::Portal;

post '/locale/:locale' => sub {
  session locale => params->{locale};
  return get();
}

sub get {
  # Show a "select locale" widget.
}

get '/locale' => \&get;

1;
