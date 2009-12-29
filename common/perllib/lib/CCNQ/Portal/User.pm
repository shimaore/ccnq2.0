package CCNQ::Portal::User;

use strict; use warnings;
use base CCNQ::Object;

# Class method: load an existing user from the database.

sub load {
  my ($username) = @_;
  # Access the database to load information about the specified user.

  return new CCNQ::Portal::User %params;
}

sub _init {
  my $self = shift;
  my %params = @_;
  foreach (qw(username name email default_language)) {
    $self->{$_} = $params{$_};
  } 
}

=pod
  name
    Returns a human-readable name (e.g. first name and last name) for this user.
=cut

sub name { return shift->{name} }

=pod
  email
    Returns a valid SMTP email address.
=cut

sub email { return shift->{email} }

sub default_language {
  my $self = shift;
  return $self->{default_language};
}

1;
