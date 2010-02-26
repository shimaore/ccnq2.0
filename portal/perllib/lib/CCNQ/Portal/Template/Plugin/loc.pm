package CCNQ::Portal::Template::Plugin::loc;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use CCNQ::Portal;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    my $name = $self->{_CONFIG}->{name} || 'loc';
    $self->install_filter($name);
    return $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;

    $text = CCNQ::Portal->current_session->locale->loc($text,@{$args});
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
    }
    return $text;
}

=head1
Internationalization Filter for Template-Toolkit.

This filter also does html expansion (like the default "html" filter),
since apparently custom filters cannot be part of a chain of filters.

This is therefor suitable for use in HTML content and values.

Use as follows:

    <% | loc %>String to be localized<% END %>

    <% | loc param1 %>String with param [_1]<% END %>

=cut

'CCNQ::Portal::Template::Plugin::loc';
