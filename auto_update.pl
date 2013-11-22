#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";

use head_check;
use mirror;


use Capture::Tiny qw(capture);
use Path::Tiny;
use Git::Wrapper;

sub CPAN_test_index {
    my ($author) = @_;
    return 'http://www.cpantesters.org/author/' . $author . '.json';
}


my $CPAN_ID;

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

print "Updating HEAD\n";

my $result =
  head_check::URI_Changed( CPAN_test_index($CPAN_ID), $LAST_MODIFIED_FILE, $HEADERS_FILE );

if ( not $result ) { 
    print "No changes since last snapshot\n";
}
if ( $result or not -e $JSON_FILE ) {
    print "Syncing $JSON_FILE\n";
    ## Change this if you don't have "axel"
    mirror::axel( CPAN_test_index($CPAN_ID), $JSON_FILE );
}

if ( $result or not -e $REPORT_FILE ) {

    require DistSet;

    my $dists = DistSet->new();

    require JSON::XS;
    my $tiny = JSON::XS->new();
    
    my $bytes = $JSON_FILE->slurp_utf8();
    my $array = $tiny->decode($bytes);
    
    for my $item ( @{$array} ) {
        $dists->add_info($item);
    }
    my $sorter = sub {
        my $d = $a->num_pass <=> $b->num_pass;
        return $d unless $d == 0;
        $d = $a->num_fail <=> $b->num_fail;
        return $d unless $d == 0;
        return $a->name cmp $b->name;
    
        #return $a->fail_rate <=> $b->fail_rate;
        if ( $a->num_fail != $b->num_fail ) { 
            return $a->num_fail <=> $b->num_fail;
        }
        if ( $a->num_pass != $b->num_pass ) {
            return $a->num_pass <=> $b->num_pass;
        }
        return 1;
    };
    my @lines;
    for my $xitem ( sort { $sorter->() } $dists->all_versions ) {
       next if not defined $xitem;
       push @lines, sprintf "%s\n", $xitem->to_s;
    }   
    $REPORT_FILE->spew_utf8(@lines);
}

__END__

print "Updating HEAD\n";
my ( $stdout, $stderr, $exit ) = capture {
    system('git','diff','--','HEAD');
};
print "Done\n";
my $mod;
if ( $stdout =~ /^[+]Last-Modified: (.*?$)/msx ) {
    print "Modified, syncing JSON\n";
    $mod = $1;
    system('bash', './sync_axel.sh');
    my ( $c_out, $c_err, $c_exit ) = capture {
        system('perl','./e.pl');
    };
    print "Updating data\n";
    path('./data')->spew_raw($c_out);
    system('git','add','--','HEAD','data', $CPAN_ID . '.json');
    system('git','commit','-m', "Sync to $mod");
} else {
    print "Not modified\n";
}


