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
        [qw/running pending shutting-down terminated stopping stopped/],
    },
);
no Mouse;

use Yogafire::Instance::Action::Info;
use Yogafire::Term;

sub run {
    my ($self, $instance, $opt) = @_;
    $opt ||= {};
    my $force = $opt->{force};

    unless($force) {
        # show info
        Yogafire::Instance::Action::Info->new()->run($instance);

        my $term = Yogafire::Term->new();
        print "\n";
        return unless $term->ask_yn(
            prompt   => 'Are you sure you want to terminate this instance? > ',
        );
    }

    print "Instance terminate... \n";
    $instance->terminate;
    print "Instance terminate in process. \n";
};

1;
