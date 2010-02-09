package CCNQ::Portal::User;

use strict; use warnings;

use CCNQ::Portal::UserProfile;

=pod

  new CCNQ::Portal::User $user_id

=cut

sub new {
    my $this = shift; my $class = ref($this) || $this;
    my $self = { _id => $_[0] };
    return bless $self, $class;
}

sub id {
  my $self = shift;
  return $self->{_id};
}

sub profile {
  my $self = shift;
  return $self->{_profile} ||= new CCNQ::Portal::UserProfile::load($self->id);
}

1;
