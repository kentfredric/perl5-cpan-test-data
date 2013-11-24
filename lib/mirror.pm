
use strict;
use warnings;

package mirror;

sub axel {
    my ( $uri, $target ) = @_;
    unlink $target;
    my $exit = system( 'axel', '-n', '20', '-o', $target, '-v', '-a', $uri );
    die "Mirror Failed: $! $? $@" if $exit != 0;
}

sub wget {
    my ( $uri, $target ) = @_;
    my $exit = system( 'wget', $uri, '-O', $target );
    die "Mirror Failed: $! $? $@" if $exit != 0;
}

1;
