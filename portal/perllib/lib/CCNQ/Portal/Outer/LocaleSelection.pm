package CCNQ::Portal::Outer::UserAuthentication;

use CCNQ::Portal::Outer::Widget qw(if_ok);

use Dancer ':syntax';
use CCNQ::Portal;

post '/locale/:locale' => sub {
  session locale => params->{locale};
  return get();
}

sub html {
  # Show a "select locale" widget.
}

get '/locale' => \&html;

1;
