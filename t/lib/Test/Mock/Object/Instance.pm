package Test::Mock::Object::Instance;

use strict;
use warnings;
use Test::MockObject;

my @attrs = qw/
    instanceId
    ownerId
    reservationId
    imageId
    instanceState
    groups
    privateIpAddress
    ipAddress
    privateDnsName
    dnsName
    launchTime
    current_status
    start
    stop
    reboot
    terminate
    up_time
    instance_id
    ip_address
    private_ip_address
    dns_name
    monitoring
    placement
/;

sub create {
    my ($attr) = @_;
    $attr ||= {};

    $attr->{instance_id} = $attr->{instanceId} if $attr->{instanceId};
    $attr->{instanceId} = $attr->{instance_id} if $attr->{instance_id};

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
    my $state = $attr->{state} || 'running';
    $mock->{data}->{instanceState} = {};
    $mock->{data}->{instanceState}->{name} = $state;

    return $mock;
}

1;
