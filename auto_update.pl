#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";

use Path::Tiny;

sub CPAN_test_index {
    my ($author) = @_;
    return 'http://www.cpantesters.org/author/' . $author . '.json';
}

my $CPAN_ID;
my $AUTOCOMMIT;

for my $param ( 0 .. $#ARGV ) {
    if ( $ARGV[$param] =~ /^--commit$/msx ) {
        $AUTOCOMMIT = 1;
        $ARGV[$param] = undef;
    }
}
@ARGV = grep { defined } @ARGV;

if ( $ARGV[0] ) {
    $CPAN_ID = $ARGV[0];
}
else {
    $CPAN_ID = path('CPANID')->slurp_utf8();
    chomp $CPAN_ID;
}
my $LAST_MODIFIED_FILE = path( $CPAN_ID . '.last_modified' );
my $JSON_FILE          = path( $CPAN_ID . '.json' );
my $HEADERS_FILE       = path( $CPAN_ID . '.HEAD' );
my $REPORT_FILE        = path( $CPAN_ID . '.data' );
my $VREPORT_FILE       = path( $CPAN_ID . '.data.versions' );

print "Updating HEAD\n";

require head_check;

my $result = head_check::URI_Changed( CPAN_test_index($CPAN_ID),
    $LAST_MODIFIED_FILE, $HEADERS_FILE );

my $modified;
if ( not $result ) {
    print "No changes since last snapshot\n";
}
if ( $result or not -e $JSON_FILE ) {
    print "Syncing $JSON_FILE\n";
    require mirror;
    ## Change this if you don't have "axel"
    mirror::axel( CPAN_test_index($CPAN_ID), $JSON_FILE );
    $modified = 1;
}

if ( $result or not -e $REPORT_FILE ) {

    require DistSet;

    my $dists = DistSet->read_file( $JSON_FILE );

    my @lines;
    for my $xitem ( $dists->all_versions_by(qw( num_pass num_fail )) ) {
        next if not defined $xitem;
        push @lines, sprintf "%s\n", $xitem->to_s;
    }
    $REPORT_FILE->spew_utf8(@lines);
    $modified = 1;

}
if ( $result or not -e $VREPORT_FILE ) {

    require DistSet;

    my $dists = DistSet->read_file( $JSON_FILE );

    my @lines;
    for my $xitem ( $dists->all_versions_by(qw( num_pass num_fail )) ) {
        next if not defined $xitem;
        push @lines, map { sprintf "%s\n", $_ } $xitem->to_perlver_breakdown;
    }
    $VREPORT_FILE->spew_utf8(@lines);
    $modified = 1;

}
if ( $AUTOCOMMIT and $modified ) {
    print "Autocommit\n";
    require Git::Wrapper;
    my $git = Git::Wrapper->new('.');
    $git->add($LAST_MODIFIED_FILE);
    $git->add($HEADERS_FILE);
    $git->add($REPORT_FILE);
    $git->add($VREPORT_FILE);
    my ($ts) = $LAST_MODIFIED_FILE->lines_utf8( { chomp => 1 } );
    eval {
        $git->commit( '-m', "Sync $CPAN_ID data to $ts",
            $LAST_MODIFIED_FILE, $HEADERS_FILE, $REPORT_FILE, $VREPORT_FILE );
    };
    print "Done!\n";
}

