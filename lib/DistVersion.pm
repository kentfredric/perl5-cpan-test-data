
use strict;
use warnings;

package DistVersion;
use Class::Tiny qw(name version),
  {
    pass    => sub { [] },
    fail    => sub { [] },
    na      => sub { [] },
    unknown => sub { [] },
  };

sub num_pass    { return scalar @{ $_[0]->pass } }
sub num_fail    { return scalar @{ $_[0]->fail } }
sub num_na      { return scalar @{ $_[0]->na } }
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
    my ($self) = @_;
    return sprintf qq[%100s:\t%s\t%s\t%s\t%s],
      $self->name . '-' . $self->version,
      $self->num_pass,
      $self->num_fail,
      $self->num_na,
      $self->num_unknown;
}

1;
