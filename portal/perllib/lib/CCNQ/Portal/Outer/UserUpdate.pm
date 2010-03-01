package CCNQ::Portal::Outer::UserUpdate;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;

use CGI::Untaint;

sub retrieve {
  my ($user_id) = @_;

  my $user = CCNQ::Portal::User->new($user_id);
  return unless $user->profile;

  var field => {
    name              => $user->profile->name,
    email             => $user->profile->email,
    default_language  => $user->profile->default_locale,
    portal_accounts   => join(' ',@{$user->profile->portal_accounts}),
    is_admin          => $user->profile->portal_accounts,
    # XXX billing_accounts (via API)
    # XXX other billing/provisioning -side data
  };
}

sub update {
  my ($user_id) = @_;

  my $user = CCNQ::Portal::User->new($user_id);
  return unless $user->profile;

  my $untainter = CGI::Untaint->new(params);

  my $params = {
    default_language => params->{default_language},
  };
  # XXX Replace with a global list of supported languages.
  unless(grep { $params->{default_language} eq $_} qw( en fr )) {
    var error => _('Invalid language')_;
    return;
  }

  if(CCNQ::Portal->current_session->user->profile->is_admin) {
    # Name
    $params->{name} = $untainter->extract(-as_printable=>params->{name});

    # Email address
    my $email = $untainter->extract(-as_email=>params->{email});
    if($email) {
      $params->{email} = $email->format;
    } else {
      var error => _('Invalid email address')_;
      return;
    }

    # Portal accounts
    my @portal_accounts = split(' ',params->{portal_accounts});
    # XX Check the accounts are valid accounts. (Requires API access.)
    $params->{portal_accounts} = [@portal_accounts];

    # XXX Billing accounts
  }

  if(CCNQ::Portal->current_session->user->profile->is_sysadmin) {
    $params->{is_admin} = params->{is_admin};
  }

  $user->profile->update($params);
}

get '/user_profile' => sub {
  return unless CCNQ::Portal->current_session->user;
  var template_name => 'user_profile';
  retrieve(CCNQ::Portal->current_session->user->id);
  return CCNQ::Portal->site->default_content->();
};

get '/user_profile/:user_id' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless CCNQ::Portal->current_session->user->profile->is_admin;
  var template_name => 'user_profile';
  retrieve(params->{user_id});
  return CCNQ::Portal->site->default_content->();
};

# Regular user updates their own profile.
post '/user_profile' => sub {
  return unless CCNQ::Portal->current_session->user;
  var template_name => 'user_profile';
  update(CCNQ::Portal->current_session->user->id);
  return CCNQ::Portal->site->default_content->();
};

# Admin updates another user's profile.
post '/user_profile/:user_id' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless CCNQ::Portal->current_session->user->profile->is_admin;
  var template_name => 'user_profile';
  update(params->{user_id});
  return CCNQ::Portal->site->default_content->();
};

'CCNQ::Portal::Outer::UserUpdate';
