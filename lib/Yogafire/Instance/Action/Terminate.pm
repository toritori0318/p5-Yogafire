package Yogafire::Instance::Action::Terminate;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'terminate');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running pending stopped/],
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
            prompt   => 'Are you sure you want to terminate this instance? > ',
        );
    }

    yinfo(resource => $instance, message => "<<<Start>>> Instance terminate.");
    $instance->terminate;
    yinfo(resource => $instance, message => "<<<End>>> Instance terminate.");
};

1;
