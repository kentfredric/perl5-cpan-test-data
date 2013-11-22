use strict;
use warnings;

package Dist;

use Class::Tiny qw(name), {
    versions => sub { {} }
};

sub add_info {
    my ( $self, $rec ) = @_;
    my $version = $rec->{version};
    if ( not exists $self->versions->{$version} ) {
        require DistVersion;
        $self->versions->{$version} =
          DistVersion->new( name => $self->name, version => $version );
    }
    $self->versions->{$version}->add_info($rec);
}

sub to_s {
    my ($self) = @_;
    return join qq[\n], map { $_->to_s } values %{ $self->versions };
}

sub all_versions {
    my ($self) = @_;
    return values %{ $self->versions };
}

1;
