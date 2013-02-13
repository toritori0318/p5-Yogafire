package Yogafire::ActionBase;
use strict;
use warnings;

use Mouse;
has 'ec2'    => (is => 'rw', isa => 'VM::EC2');
has 'config' => (is => 'rw', isa => 'Yogafire::Config');
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
