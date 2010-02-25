package portal;
use Dancer;
use Template;
use CCNQ::Portal;

=pod

Would need to be able to pass:
  PLUGINS => {
    loc => 'CCNQ::Template::Plugin::loc',
  },
to Template->new.

=cut

use CCNQ::Portal::Outer::UserAuthentication;
use CCNQ::Portal::Outer::AccountSelection;

# before sub {
#     if (!session('user_id') && request->path_info !~ m{^/(login|public)}) {
#         # Pass the original path requested along to the handler:
#         var requested_path => request->path_info;
#         request->path_info('/login');
#     }
# };

get '/' => sub {
  my $template_name = 'index';
  $template_name = 'result' if vars->{result};
  my $vars = vars;
  template $template_name {
    lh => CCNQ::Portal->current_session->locale,
    accounts => CCNQ::Portal::Outer::AccountSelection->available_accounts,
    account => CCNQ::Portal::Outer::AccountSelection->set,
    %{$vars},
  };
};

true;