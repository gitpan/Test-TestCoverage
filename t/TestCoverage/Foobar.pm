package TestCoverage::Foobar;

use strict;
use warnings;

use Moose;

has 'attr' => (
    is => 'rw',
    isa => 'Str',
);

sub BUILD {
    my $self = shift;

    $self->attr( 'foobar' );
}

1;
