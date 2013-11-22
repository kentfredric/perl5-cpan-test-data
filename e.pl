#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;

{

    package Version;
    use Class::Tiny qw(name version),
      {
        pass    => sub { [] },
        fail    => sub { [] },
        na      => sub { [] },
        unknown => sub { [] },
      };


    sub num_pass { return scalar @{ $_[0]->pass } }
    sub num_fail { return scalar @{ $_[0]->fail } }
    sub num_na { return scalar @{ $_[0]->na } }
    sub num_unknown { return scalar @{ $_[0]->unknown } }
    sub fail_rate {
        if ( $_[0]->num_pass + $_[0]->num_fail < 1 ) {
            return 0;
        }
        return $_[0]->num_fail / ( $_[0]->num_pass + $_[0]->num_fail );
    }

    sub add_info {
        my ( $self, $rec ) = @_;
        my $target = $rec->{state};
        if ( my $method = $self->can($target) ) {
            push @{ $self->$method() }, $rec;
            return;
        }
        die "No such state $rec->{state}";
    }
    sub to_s {
        my ( $self ) = @_;
        return sprintf qq[%100s:\t%s\t%s\t%s\t%s], 
            $self->name . '-' .   $self->version,
            $self->num_pass,
            $self->num_fail,
            $self->num_na,
            $self->num_unknown;
    }
}
{

    package Dist;
    use Class::Tiny qw(name), {
        versions => sub { {} }
    };

    sub add_info {
        my ( $self, $rec ) = @_;
        my $version = $rec->{version};
        if ( not exists $self->versions->{$version} ) {
            $self->versions->{$version} =
              Version->new( name => $self->name, version => $version );
        }
        $self->versions->{$version}->add_info($rec);
    }
    sub to_s {
        my ( $self ) = @_;
        return join qq[\n], map { $_->to_s } values %{ $self->versions  };
    }
    sub all_versions {
        my ( $self ) = @_;
        return values %{ $self->versions };
    }
}
{

    package DistSet;
    use Class::Tiny {
        dists => sub { {} }
    };

    sub add_info {
        my ( $self, $rec ) = @_;
        my $dist = $rec->{distribution};
        if ( not exists $self->dists->{$dist} ) {
            $self->dists->{$dist} = Dist->new( name => $dist );
        }
        $self->dists->{$dist}->add_info($rec);
    }
    sub to_s {
        my ( $self ) = @_;
        return join qq[\n], map { $_->to_s } values %{ $self->dists  };
    }
    sub all_versions {
        my ( $self ) = @_;
        return map { $_->all_versions } values %{ $self->dists };
    }
}
use JSON::XS;
my $tiny = JSON::XS->new();
use Path::Tiny qw(path);
my $bytes = path('./KENTNL.json')->slurp_utf8();
my $array = $tiny->decode($bytes);

my $dists = DistSet->new();

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
use Data::Dump qw(pp);

for my $xitem ( sort { $sorter->() } $dists->all_versions ) {
   next if not defined $xitem;
   printf "%s\n", $xitem->to_s;
}
#my @fails;
#for my $item ( grep { $_->num_fail > 0 } $dists->all_versions ) {
#    push @fails, @{ $item->fail };
#}
#for my $fail ( sort { $a->{fulldate} <=> $b->{fulldate} } @fails ){ 
#    printf "\e[31m%s\e[0m on \e[33m %s \e[0m ( %s ) by %s at %s = \e[32m http://www.cpantesters.org/cpan/report/%s \e[0m\n",
#        $fail->{distversion},
#        $fail->{osname},
#        $fail->{ostext} . q[ ]. $fail->{osvers} . q[ ] . $fail->{perl} . q[ ] . $fail->{platform},
#        $fail->{tester},
#        $fail->{fulldate},
#        $fail->{guid};
#}

    #pp($dists);
