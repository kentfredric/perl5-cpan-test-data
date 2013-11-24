
use strict;
use warnings;

package DistVersion;
use version;
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

sub _fmt {
    my ( $self, @args ) = @_;
    return sprintf qq[%100s:\t%s\t%s\t%s\t%s], @args;
}
sub _fmt_hl {
    my ( $self, @args ) = @_;
    return sprintf qq{\e[36m%100s\e[0m:\t\e[32m%s\e[0m\t\e[31m%s\e[0m\t\e[33m%s\e[0m\t\e[34m%s\e[0m}, @args;
}
sub to_s {
    my ($self) = @_;
    return $self->_fmt(  $self->name . '-' . $self->version,
      $self->num_pass,
      $self->num_fail,
      $self->num_na,
      $self->num_unknown );
}
sub to_s_hl {
    my ($self) = @_;
    return $self->_fmt_hl(
      $self->name . '-' . $self->version,
      $self->num_pass,
      $self->num_fail,
      $self->num_na,
      $self->num_unknown );

}
use Data::Dump qw(pp);
sub to_perlver_breakdown {
    my ( $self ) = @_;
    my @out;
    push @out, $self->to_s_hl;

    my %stats;
    for my $grade ( qw( pass fail na unknown ) ) {
        for my $result (@{ $self->$grade() } ) {
            my $perl = $result->{perl};
            $perl =~ s/^(\d+[.]\d+).*$/v$1/;
            $stats{ $perl } = { pass => 0, fail => 0, na => 0, unknown => 0 } unless exists $stats{$perl};
            $stats{ $perl }{$grade}++;
        }
    }
    my $vcmp = sub {
        my ( $xa, $xb ) = ($a,$b);
        $xa =~ s/\s.*$//;
        $xb =~ s/\s.*$//;
        $xa = version::->parse($xa) ;#if defined $xa and version::is_lax($xa);
        $xb = version::->parse($xb) ;#if defined $xb and version::is_lax($xa);
        return $xa <=> $xb;
    };
    for my $version ( sort { $vcmp->($a,$b) } keys %stats ) {
        my $data = $stats{$version};
        push @out, $self->_fmt( $version, $data->{pass}, $data->{fail}, $data->{na}, $data->{unknown} );
    }
    return @out;

}

1;
