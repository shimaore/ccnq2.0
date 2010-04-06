package portal;
use Dancer;
use Template;
use Encode;

use CCNQ;
set views => [
  path(CCNQ::CCN, 'views'),
  path(CCNQ::Portal::SRC, 'views'),
];

set public => path(CCNQ::Portal::SRC, 'public');

use CCNQ::Portal::Site;
use CCNQ::Portal::Auth::CouchDB;
my $site = CCNQ::Portal::Site->new(
  default_locale => 'en-US',
  security => CCNQ::Portal::Auth::CouchDB->new(),
  default_content => sub {
    my $template_name = 'index';
    $template_name = 'result' if vars->{result};
    $template_name = vars->{template_name} if vars->{template_name};

    my $vars = vars;

    if(CCNQ::Portal->current_session->user) {
      $vars->{user_name} =
        CCNQ::Portal->current_session->user->profile->name;
      $vars->{is_admin} =
        CCNQ::Portal->current_session->user->profile->{is_admin} || 0;
      $vars->{is_sysadmin} =
        CCNQ::Portal->current_session->user->profile->{is_sysadmin} || 0;
    }

    encode_utf8 template $template_name => {
      %{$vars},
      lh => CCNQ::Portal->current_session->locale,
      accounts => CCNQ::Portal::Outer::AccountSelection->available_accounts,
      account => CCNQ::Portal::Outer::AccountSelection->account,
    };
  },
);

use CCNQ::Portal;
CCNQ::Portal->import($site);

use CCNQ::Portal::Outer::UserAuthentication;
use CCNQ::Portal::Outer::UserUpdate;
use CCNQ::Portal::Outer::AccountSelection;
use CCNQ::Portal::Outer::LocaleSelection;

use CCNQ::Portal::Inner::billing_plan;

any '/' => sub {
  $site->default_content->();
};

true;
