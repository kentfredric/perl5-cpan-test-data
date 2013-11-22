#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;


use JSON::XS;
my $tiny = JSON::XS->new();
use Path::Tiny qw(path);
my $bytes = path('./KENTNL.json')->slurp_utf8();
my $array = $tiny->decode($bytes);

for my $item ( @{$array} ) {
   next unless $item->{distribution} eq $ARGV[0];
   next unless $item->{status} ne 'PASS';
   print $item->{status} . ' -> http://www.cpantesters.org/cpan/report/' . $item->{guid} . ' -> ' . $item->{osname} . "\n";
}
