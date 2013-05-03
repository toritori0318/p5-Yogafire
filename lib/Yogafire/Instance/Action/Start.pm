package Yogafire::Instance::Action::Start;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'start');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/stopped/],
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
            prompt   => 'Are you sure you want to start this instance? > ',
        );
    }

    yinfo(resource => $instance, message => "<<<Start>>> Instance start.");
    $instance->start;
    yinfo(resource => $instance, message => "<<<End>>> Instance start.");
};

1;
