package CCNQ::Portal::Template::Plugin::loc;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use CCNQ::Portal::I18N;

sub init {
    my $self = shift;
    $self->{ _DYNAMIC } = 1;
    return $self;
}

sub filter {
    my ($self, $text) = @_;

    my $args = $self->{_ARGS};
    return _($text,@{$args})_;
}

'CCNQ::Portal::Template::Plugin::Loc';
