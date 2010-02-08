package CCNQ::Portal::Outer::AccountSelection;

use constant ACCOUNT_PARAM         => 'account';          # Form param name
use constant SESSION_ACCOUNT_PARAM => 'current_account';  # Session param name

# We are a widget!
use base CCNQ::Portal::Outer::Widget;

sub set_account {
  my ($self,$new_account) = @_;
  $self->session->param(SESSION_ACCOUNT_PARAM,$new_account);
}

sub get_account {
  my ($self) = @_;
  return $self->session->param(SESSION_ACCOUNT_PARAM);
}

sub out {
  XXX Return a form that allows for account selection
  
  my $accounts = $self->session->user->profile->portal_accounts;
  if($#accounts == -1) {
    # Account selection is not possible, the user does not have access to any account
  } elsif($#accounts == 0) {
    # Only one account is available, no need to "select" this one -- enforce it.
    $self->set_account($account[0]);
  } elseif($#accounts == 0) {
    XXX
    # Return a form with a single select where the list of possible values is 
    @{$accounts}
    # and the current selected item is
    $self->get_account();
    # ...
  }
}

sub in {
  my $self = shift;
  my ($untainter) = @_;

  my $new_account = $untainter->extract(-printable=>ACCOUNT_PARAM);

  return ['error',_('Account name not specified')_]
    unless $new_account;

  my $accounts = $self->session->user->profile->portal_accounts;
  if($accounts && grep { $_ eq $new_account } @{$accounts}) {
    $self->set_account($new_account);
    return ['ok'];
  } else {
    return ['error',_('Invalid account')_];
  }
}

1;
