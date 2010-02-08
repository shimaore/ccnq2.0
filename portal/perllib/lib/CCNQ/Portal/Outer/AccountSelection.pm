package CCNQ::Portal::Outer::AccountSelection;

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;

use CGI::FormBuilder;

sub available_accounts {
  if(CCNQ::Portal::current_session->user) {
    return CCNQ::Portal::current_session->user->profile->portal_accounts;
  } else {
    return [];
  }
}

sub form {
  my $form = new CGI::FormBuilder (
    name => 'account_selection',
    method => 'post',
    values => { account => session('account') },
    submit => 1,
  );
  $form->field(
    name => 'account',
    label => _('Account')_,
    options => available_accounts(),
    message => _('Invalid account')_,
    required => 1,
  );
} 

=pod

  CCNQ::Portal::Outer::AccountSelection
    Allows the user to select the "current account" they are working
    with inside the portal.

=cut

sub html {
  my $accounts = available_accounts;

  if($#{$accounts} == -1) {
    # Account selection is not possible, the user does not have access to any account
    session account => undef;
    # XXX Generally here I have a little commercial blurb (upsell).
    return _('No account available.')_;
  } elsif($#{$accounts} == 0) {
    # Only one account is available, no need to "select" this one -- enforce it.
    session account => $accounts->[0];
    return _('Account [_1]',$accounts->[0])_;
  } elsif($#{$accounts} > 0) {
    return form->render;
  }
}

post '/account/:account' => sub {
  # Note: we don't use CGI::FormBuilder's here.
  my $account = params->{account};
  my $accounts = available_accounts;
  session account => $account
    if defined $accounts && defined $account
    && grep { $_ eq $account } @{$accounts};

  return get();
};

get '/account' => \&html;

'CCNQ::Portal::Outer::AccountSelection';
