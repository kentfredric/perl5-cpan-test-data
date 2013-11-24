#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use JSON::XS;
my $tiny = JSON::XS->new();
use Path::Tiny qw(path);

my $CPAN_ID;
if ( $ARGV[0] ) {
    $CPAN_ID = $ARGV[0];
    shift @ARGV;
}
else {
    $CPAN_ID = path('CPANID')->slurp_utf8();
    chomp $CPAN_ID;
}
my $JSON_FILE = path( $CPAN_ID . '.json' );

my $bytes = $JSON_FILE->slurp_utf8();
my $array = $tiny->decode($bytes);

binmode *STDOUT, ':utf8';

sub highlight {
    my ( $status, $text ) = @_;
    my $color = '';
    $color = "\e[31m" if $status eq 'FAIL';
    $color = "\e[32m" if $status eq 'PASS';
    $color = "\e[33m" if $status eq 'NA';
    $color = "\e[34m" if $status eq 'UNKNOWN';
    return $color . $text . "\e[0m";
}

sub pad_highlight {
    my ( $status, $len, $text ) = @_;
    if ( ( length $text ) < $len ) {
        my $extra = $len - length $text;
        $text = ( q[ ] x $extra ) . $text;
    }
    return highlight( $status, $text );
}

sub lpad_highlight {
    my ( $status, $len, $text ) = @_;
    if ( ( length $text ) < $len ) {
        my $extra = $len - length $text;
        $text = $text . ( q[ ] x $extra );
    }
    return highlight( $status, $text );
}

sub hlpair {
    my ( $l, $r ) = @_;
    print "\e[37m$l:\e[0m $r, ";
}
for my $item ( sort { $a->{fulldate} <=> $b->{fulldate} } @{$array} ) {
    if ( $ARGV[0] ) {
        next unless $item->{distribution} eq $ARGV[0];
    }
    next unless $item->{status} ne 'PASS';

    print pad_highlight( $item->{status}, 4, $item->{status} );
    print ' - ';
    print lpad_highlight( $item->{status}, 60, $item->{distversion} );
    print "\n";
    print "\t";
    for my $key (
        qw( osname ostext osvers fulldate platform csspatch cssperl perl ))
    {
        hlpair( $key, $item->{$key} );
    }
    print "\n";
    print "\t";
    for my $key (qw( tester )) {
        hlpair( $key, $item->{$key} );
    }
    print lpad_highlight( $item->{status}, 60,
        "http://www.cpantesters.org/cpan/report/" . $item->{guid} );

    print "\n";

    next;
}

print "keys: ";
print join q[,], sort keys %{ $array->[0] };
print "\n";

