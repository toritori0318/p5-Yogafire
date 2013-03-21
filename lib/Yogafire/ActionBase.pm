package Yogafire::ActionBase;
use strict;
use warnings;

use Mouse;
no Mouse;

sub run {
    my ($self, $instances, $opt) = @_;
    $self->proc($_, $opt) for @$instances;
}

sub proc {
    my ($self, $instances, $opt) = @_;
    die '[proc] is abstract method. ';
}

1;
