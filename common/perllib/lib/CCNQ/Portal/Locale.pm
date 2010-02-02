package CCNQ::Portal::Locale;

=pod

  new CCNQ::Portal::User $user_id

=cut

sub new {
    my $this = shift; my $class = ref($this) || $this;
    my $self = { _locale => $_[0] };
    return bless $self, $class;
}

sub id { $self->{_locale} }

sub lang {
  my $self = shift;
  $self->{_lang} ||= CCNQ::I18N->get_handle($self->current_locale);
}

sub loc {
  $self->lang->maketext(@_);
}

sub loc_duration {}

sub loc_timestamp {}

sub loc_date {}

sub loc_amount {
  my $self = shift;
  my ($currency,$value) = @_;
}

'CCNQ::Portal::Locale';
