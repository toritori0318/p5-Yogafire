package Yogafire::Instance::Action::SSH;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'ssh');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running/],
    },
);
no Mouse;

use Yogafire::Instance qw/list/;

sub proc {
    my ($self, $instance, $opt) = @_;

    my $identity_file = $opt->{identity_file} || $self->config->get('identity_file') || '';
    my $user          = $opt->{user} || $self->config->get('ssh_user') || '';
    my $ssh_port      = $opt->{port} || $self->config->get('ssh_port') || '22';

    my @cmd;
    if($opt->{proxy}) {
        $opt->{tagsname} = $opt->{proxy};
        my @proxy_servers = list($self->ec2, $opt);
        my $proxy_server  = shift @proxy_servers;
        die "Not found proxy server.\n" unless $proxy_server;

        my $proxy_host = $proxy_server->ipAddress;
        my @proxy_cmd  = ('ssh', '-W %h:%p', '-i', $identity_file, '-l', $user, $proxy_host);
        my $host = $instance->privateIpAddress;
        @cmd = ('ssh', '-p', $ssh_port, '-i', $identity_file, '-l', $user, '-oProxyCommand="', join(' ', @proxy_cmd) ,'"', $host);
    } else {
        my $host = $instance->ipAddress;
        @cmd = ('ssh', '-p', $ssh_port, '-i', $identity_file, '-l', $user, $host);
    }

    print join(' ', @cmd), "\n";
    exec(join(' ', @cmd));
};

1;

