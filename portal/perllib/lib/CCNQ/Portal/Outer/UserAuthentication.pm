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
    my $result = logout_widget->render;
    # Show a link to a "switchuser" widget
    # TBD
    return $result;
  } else {
    # Show a "login" widget
    my $result = authenticate_widget->render;
    # Show a link to a "register" widget
    # TBD
    return $result;
  }
}

sub authenticate_widget {
  my $form = CGI::FormBuilder->new(
    name => 'authenticate',
    method => 'POST',
    values => {},
    # Actual validation is done in Outer::UserAuthentication
    validate => {
      CCNQ::Portal::site->security->USERNAME_PARAM() => 'VALUE',
      CCNQ::Portal::site->security->PASSWORD_PARAM() => 'VALUE',
    },
    action => '/login',
  );
  $form->field(
    name => USERNAME_PARAM(),
    label => _('Username')_,
    required => 1,
  );
  $form->field(
    name => PASSWORD_PARAM(),
    type => 'password',
    label => _('Password')_,
    required => 1,
  );
  return $form;
}

sub logout_widget {
  my $form = CGI::FormBuilder->new(
    name => 'logout',
    method => 'GET',
    action => '/logout',
  );
}

get '/login' => \&widget;

'CCNQ::Portal::Outer::UserAuthentication';
