
use strict;
use warnings;

package DistSet;

use Path::Tiny qw(path);

use Class::Tiny {
    dists => sub {
        return {}
    },
    decoder => sub {
        require JSON::XS;
        return JSON::XS->new();
    },
};

sub add_info {
    my ( $self, $rec ) = @_;
    my $dist = $rec->{distribution};
    if ( not exists $self->dists->{$dist} ) {
        require Dist;
        $self->dists->{$dist} = Dist->new( name => $dist );
    }
    $self->dists->{$dist}->add_info($rec);
}

sub to_s {
    my ($self) = @_;
    return join qq[\n], map { $_->to_s } values %{ $self->dists };
}

sub all_versions {
    my ($self) = @_;
    return map { $_->all_versions } values %{ $self->dists };
}

sub all_versions_by {
    my ( $self, @fields ) = @_;

    my $sorter = sub {
        my $cmp;
        for my $field ( @fields ) {
            $cmp = ( $a->$field() <=> $b->$field() );
            return $cmp unless $cmp == 0;
        }
        return $cmp;
    };
    return ( my @list =  sort { $sorter->() } $self->all_versions );
}

sub read_file {
    my ( $class, $file ) = @_;
    my $instance = $class->new();
    my $array = $instance->decoder->decode(path($file)->slurp_utf8);
    for my $item ( @{ $array } ) {
        $instance->add_info( $item );
    }
    return $instance;
}



1
