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

use Yogafire::Logger;
use Yogafire::Instance::Action::Info;
use Yogafire::Term;

sub proc {
    my ($self, $instance, $opt) = @_;
    $opt ||= {};
    my $force = $opt->{force};

    unless($force) {
        # show info
        Yogafire::Instance::Action::Info->new()->proc($instance);

        my $term = Yogafire::Term->new();
        print "\n";
        return unless $term->ask_yn(
            prompt   => 'Are you sure you want to reboot this instance? > ',
        );
    }

    yinfo(resource => $instance, message => "<<<Start>>> Instance reboot.");
    $instance->reboot;
    yinfo(resource => $instance, message => "<<<End>>> Instance reboot in process.");
};

1;
