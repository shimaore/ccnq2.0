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
use CCNQ::Portal::Util;

use CGI::Untaint;

use Encode;

use AnyEvent;
use CCNQ::AE;
use CCNQ::API;

sub retrieve {
  my ($user_id) = @_;

  my $user = CCNQ::Portal::User->new($user_id);

  my $cv = AE::cv;
  CCNQ::API::billing('report','users',$user_id,$cv);
  my $r = CCNQ::AE::receive($cv);
  my $billing_user_data = $r->{rows}->[0]->{doc} || {};

  var field => {
    id                => $user->id,
    name              => $user->profile->name,
    email             => $user->profile->email,
    default_locale    => $user->profile->default_locale,
    portal_accounts   => join(' ',@{$user->profile->portal_accounts}),
    is_admin          => $user->profile->is_admin,
    is_sysadmin       => $user->profile->is_sysadmin,
    # billing_accounts (via API)
    billing_accounts  => $billing_user_data->{billing_accounts},
    # other billing/provisioning -side data
  };
}

sub update {
  my ($user_id) = @_;

  my $user = CCNQ::Portal::User->new($user_id);

  my $untainter = CGI::Untaint->new(params);

  my $params = {
    default_locale => params->{default_locale} || '',
  };
  my $billing_params = {
    user_id       => $user_id,
  };

  if(defined(params->{default_locale}) && params->{default_locale} ne '') {
    # XXX Replace with a global list of supported languages.
    unless( grep { $params->{default_locale} eq $_} qw( en fr ) ) {
      var error => _('Invalid language')_;
      return;
    }
  }

  if( $user_id eq CCNQ::Portal->current_session->user->id ||
      CCNQ::Portal->current_session->user->profile->is_admin ) {

    CCNQ::Portal::Util::neat($params,qw(name));

    $billing_params->{name} = $params->{name};

    # Email address
    my $email = $untainter->extract(-as_email=>'email');
    if($email) {
      $params->{email} = $email->format;
      $billing_params->{email} = $params->{email};
    } else {
      if(params->{email}) {
        var error => _('Invalid email address')_;
        return;
      }
    }
  }

  if( CCNQ::Portal->current_session->user->profile->is_admin ) {
    # Portal accounts
    my @portal_accounts = split(' ',params->{portal_accounts});
    # XX Check the accounts are valid accounts. (Requires API access.)
    $params->{portal_accounts} = [@portal_accounts];

    # Billing accounts
    my @billing_accounts = split(' ',params->{billing_accounts});
    $billing_params->{billing_accounts} = [@billing_accounts];
  }

  if( CCNQ::Portal->current_session->user->profile->is_sysadmin ) {
    $params->{is_admin}    = params->{is_admin}    ? 1 : 0;
    $params->{is_sysadmin} = params->{is_sysadmin} ? 1 : 0;
  }

  # Update the portal-side data
  $user->profile->update($params);

  # Update the billing-side data
  if(keys %$billing_params) {
    my $cv = AE::cv;
    CCNQ::API::api_update('user',$billing_params,$cv);
    return CCNQ::Portal::Util::redirect_request($cv);
  }

  # Reset the session's locale to (potentially) use the new one.
  CCNQ::Portal->current_session->force_locale()
    if $user_id eq CCNQ::Portal->current_session->user->id;
}

get '/user_profile' => sub {

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var template_name => 'user_profile';
  retrieve(CCNQ::Portal->current_session->user->id);
  return CCNQ::Portal::content;
};

get '/user_profile/:user_id' => sub {

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var template_name => 'user_profile';
  retrieve(params->{user_id});
  return CCNQ::Portal::content;
};

post '/user_profile/select' => sub {

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var template_name => 'user_profile';
  retrieve(params->{user_id});
  return CCNQ::Portal::content;
};

# Regular user updates their own profile.
post '/user_profile' => sub {

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var template_name => 'user_profile';
  update(CCNQ::Portal->current_session->user->id);
  retrieve(CCNQ::Portal->current_session->user->id);
  return CCNQ::Portal::content;
};

# Admin updates another user's profile.
post '/user_profile/:user_id' => sub {

  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var template_name => 'user_profile';
  update(params->{user_id});
  retrieve(params->{user_id});
  return CCNQ::Portal::content;
};

'CCNQ::Portal::Outer::UserUpdate';
