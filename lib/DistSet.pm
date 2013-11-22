
use strict;
use warnings;

package DistSet;

use Class::Tiny {
    dists => sub { {} }
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

1
