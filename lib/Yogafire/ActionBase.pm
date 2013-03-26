package Yogafire::ActionBase;
use strict;
use warnings;

use Mouse;
no Mouse;

sub procs {
    my ($self, $instances, $opt) = @_;
    if(ref $instances eq "ARRAY") {
        $self->proc($_, $opt) for @$instances;
    } else {
        $self->proc($instances, $opt);
    }
}

sub proc {
    my ($self, $instances, $opt) = @_;
    die '[proc] is abstract method. ';
}

1;
