package Yogafire::Instance::Action::Reboot;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'reboot');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running/],
    },
);
no Mouse;

use Yogafire::Instance::Action::Info;
use Yogafire::Term;

sub run {
    my ($self, $instance) = @_;

    # show info
    Yogafire::Instance::Action::Info->new()->run($instance);

    my $term = Yogafire::Term->new();
    print "\n";
    return unless $term->ask_yn(
        prompt   => 'Are you sure you want to reboot this instance? > ',
    );

    print "Instance reboot... \n";
    $instance->reboot;
    print "Instance reboot in process. \n";
};

1;
