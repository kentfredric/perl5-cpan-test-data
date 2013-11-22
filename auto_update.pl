#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;

system('bash', './get_head.sh');

use Capture::Tiny qw(capture);
use Path::Tiny;


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
    system('git','add','--','HEAD','data','KENTNL.json');
    system('git','commit','-m', "Sync to $mod");
} else {
    print "Not modified\n";
}


