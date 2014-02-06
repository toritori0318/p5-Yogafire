package Yogafire::Instance::Action::ParamsDump;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'ec2paramsdump');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running pending shutting-down stopping stopped/],
    },
);
no Mouse;

sub proc {
    my ($self, $instance) = @_;

    my @cmds = qw/yoga run-instance/;
    push @cmds, $instance->imageId;
    push @cmds, sprintf("--availability_zone %s", $instance->placement);
    push @cmds, sprintf("--keypair %s", $instance->keyPair);
    push @cmds, sprintf("--groups %s", join(',', map { $_->groupName } $instance->groupSet));
    my @tags = map { $_."=".$instance->tags->{$_} } keys %{$instance->tags};
    push @cmds, sprintf("--tag %s", @tags);
    push @cmds, sprintf("--type %s", $instance->instanceType);

    push @cmds, "--count 1";

    print join(' ', @cmds), "\n";
};

1;
