package portal;
use Dancer;
use Template;

use CCNQ::Portal::Site;
use CCNQ::Portal::Auth::CouchDB;
my $site = CCNQ::Portal::Site->new(
  default_locale => 'en-US',
  security => CCNQ::Portal::Auth::CouchDB->new(),
  default_content => sub {
    my $template_name = 'index';
    $template_name = 'result' if vars->{result};

    my $vars = vars;

    if(CCNQ::Portal->current_session->user) {
      $vars->{user_name}
        = CCNQ::Portal->current_session->user->profile->name;
      $vars->{is_admin}
        = CCNQ::Portal->current_session->user->profile->{is_admin} || 0;
      $vars->{is_sysadmin}
        = CCNQ::Portal->current_session->user->profile->{is_sysadmin} || 0;
    }

    template $template_name => {
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
use CCNQ::Portal::Outer::AccountSelection;
use CCNQ::Portal::Outer::LocaleSelection;

# before sub {
#     if (!session('user_id') && request->path_info !~ m{^/(login|public)}) {
#         # Pass the original path requested along to the handler:
#         var requested_path => request->path_info;
#         request->path_info('/login');
#     }
# };

any '/' => sub {
  $site->default_content->();
};

true;
