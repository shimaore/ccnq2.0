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

=head1 loc Filter

Use as follows:

    <% | loc %>String to be localized<% END %>

    <% | loc param1 %>String to be localized with param [_1]<% END %>

=cut

'CCNQ::Portal::Template::Plugin::Loc';
