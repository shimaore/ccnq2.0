package CCNQ::Portal::Template::Plugin::locp;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use CCNQ::Portal;

sub init {
    my $self = shift;
    $self->{ _DYNAMIC } = 1;
    my $name = $self->{ _CONFIG }->{ name } || 'locp';
    $self->install_filter($name);
    return $self;
}

sub filter {
    my ($self, $text) = @_;

    my $args = $self->{_ARGS};
    return CCNQ::Portal->current_session->locale->loc($text,@{$args});
}

=head1 locp Filter

Use as follows:

    <% | locp %>String to be localized<% END %>

    <% | locp param1 %>String to be localized with param [_1]<% END %>

Note: locp being a dynamic filter, can be the only one applied.
(i.e. <% | locp | html %> will not work).

=cut

'CCNQ::Portal::Template::Plugin::locp';
