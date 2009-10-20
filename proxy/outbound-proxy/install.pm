use constant proxy_mode => 'proxy_mode';
use constant proxy_mode_file => File::Spec->catfile(CCN,proxy_mode);

sub run { print_to(proxy_mode_file,'outbound-proxy'); }
