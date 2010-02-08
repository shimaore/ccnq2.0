package CCNQ::Portal::Outer::UserAuthentication;

use CCNQ::Portal::Outer::Widget qw(if_ok);

use Dancer ':syntax';
use CCNQ::Portal;

sub html {
  # Show a "select locale" widget.
}

post '/locale/:locale' => sub {
  session locale => params->{locale};
  return get();
};

get '/locale' => \&html;

1;
