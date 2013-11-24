
use strict;
use warnings;

package mirror;

sub axel {
    my ( $uri, $target ) = @_;
    unlink $target;
    system( 'axel', '-n', '20', '-o', $target, '-v', '-a', $uri );
}

sub wget {
    my ( $uri, $target ) = @_;
    system( 'wget', $uri, '-O', $target );
}

1;
