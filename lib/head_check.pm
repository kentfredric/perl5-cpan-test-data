
use strict;
use warnings;

package head_check;

sub head_uri {
    my ( $uri, $config ) = @_;
    require HTTP::Request;
    require LWP::UserAgent;

    my $request = HTTP::Request->new( 'HEAD', $uri );

    if ( $config->{last_modified} ) {
        $request->header( 'If-Modified-Since', $config->{last_modified} );
    }
    my $ua       = LWP::UserAgent->new();
    my $response = $ua->request($request);
    return $response;
}

sub URI_Changed {
    my ( $uri, $disk_path, $headers_path ) = @_;
    my $last_modified;
    if ( -e $disk_path and -f $disk_path ) {
        $last_modified = $disk_path->slurp_utf8;
    }
    my $head = head_uri( $uri, { last_modified => $last_modified } );
    if ( my $lm = $head->header('Last-Modified') ) {
        $disk_path->spew_utf8($lm);
    }
    if ( $head->is_error ) {
        die "Error returned from server";
    }
    my $headers = $head->headers->as_string;
    if ( not -e $headers_path ) {
        $headers_path->spew_utf8($headers);
    }
    return if $head->code == 304;
    $headers_path->spew_utf8($headers);
    return 1;
}

1;
