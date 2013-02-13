package Test::Mock::Object::Image;

use strict;
use warnings;
use Test::MockObject;

my @attrs = qw/
    imageId
    imageLocation
    imageState
    imageOwnerId
    isPublic
    productCodes
    architecture
    imageType
    kernelId
    ramdiskId
    platform
    stateReason
    imageOwnerAlias
    name
    description
    rootDeviceType
    rootDeviceMape
    blockDeviceMapping
    virtualizationType
    hypervisor
/;



sub create {
    my ($attr) = @_;
    $attr ||= {};

    $attr->{image_id} = $attr->{imageId} if $attr->{imageId};
    $attr->{imageId} = $attr->{image_id} if $attr->{image_id};

    my $mock = Test::MockObject->new;

    for my $sub (@attrs) {
        my $value = $attr->{$sub} || '';
        $mock->set_always($sub, $value);
        $mock->{data}->{$sub} = $value;
    }

    # tags name
    my $tag = $attr->{tags_name} || '';
    $mock->set_always('tags', { Name => $tag},);

    # state
    my $state = $attr->{state} || 'available';
    $mock->set_always('imageState', $state);
    return $mock;
}

1;
