package Yogafire::Instance::Action::Info;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'info');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running pending shutting-down terminated stopping stopped/],
    },
);
no Mouse;

sub run {
    my ($self, $instance) = @_;
    my $print = sub {
        printf "  %16s: %s\n", $_[0], $_[1]||'';
    };
    printf "%s Instance Info %s\n", '='x16, '='x16;
    $print->('Name', $instance->tags->{Name});
    $print->('current_status', $instance->current_status);
    for my $key ( qw/instanceId ipAddress privateIpAddress dnsName privateDnsName imageId architecture instanceType rootDeviceType dnsName launchTime/) {
        $print->($key, $instance->{data}->{$key});
    }
    $print->('monitoring', $instance->monitoring);
    $print->('availabilityZone', $instance->placement);
    $print->('groupSet', join(',', (map {$_->groupName} $instance->groups) ) );
};

1;
