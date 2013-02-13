package Yogafire::Instance::Action::CopyAndLaunch;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'copyandlaunch');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running pending shutting-down terminated stopping stopped/],
    },
);
no Mouse;

use Yogafire::Instance::Action::Info;
use Yogafire::Image::Action::RunInstance;

sub proc {
    my ($self, $instance) = @_;

    my $tags = $instance->tags;
    $tags = grep { $_ ne 'Name' } keys %$tags;
    my $option = {
        count             => 1,
        instance_type     => $instance->instanceType,
        availability_zone => $instance->placement,
        name              => $instance->tags->{Name},
        tags              => $tags,
        keypair           => $instance->keyPair,
        groups            => [map {$_->groupName} $instance->groups],
    };
    my $image = $instance->aws->describe_images(-image_id => $instance->imageId);
    # copy launch
    Yogafire::Image::Action::RunInstance->new()->proc($image, $option);
};

1;
