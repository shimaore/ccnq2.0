package CCNQ::Portal::Outer::UserAuthentication;

use Dancer ':syntax';
use CCNQ::Portal;

use CCNQ::Portal::Outer::Widget qw(if_ok);

post '/login' => sub {
  if_ok(
    CCNQ::Portal::site->security->authenticate(params,session),
    sub {
      CCNQ::Portal::current_session->start(shift);
      return widget();
    });
}

get '/logout' => sub {
  CCNQ::Portal::current_session->end();
  return widget();
}

sub widget {
  if(session('user_id')) {
    # Show a "logout" widget
    
    # Show a link to a "switchuser" widget
  } else {
    # Show a "login" widget
    # Show a link to a "register" widget
  }
}

get '/login' => \&widget;

'CCNQ::Portal::Outer::UserAuthentication';
