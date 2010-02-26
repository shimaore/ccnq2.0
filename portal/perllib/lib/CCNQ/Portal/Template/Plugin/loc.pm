package CCNQ::Portal::Template::Plugin::loc;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use CCNQ::Portal;

sub init {
    my $self = shift;
    my $name = $self->{ _CONFIG }->{ name } || 'loc';
    $self->install_filter($name);
    return $self;
}

sub filter {
    my ($self, $text) = @_;

    return CCNQ::Portal->current_session->locale->loc($text);
}

=head1 loc Filter

Use as follows:

    <% | loc %>String to be localized<% END %>

=cut

'CCNQ::Portal::Template::Plugin::loc';
