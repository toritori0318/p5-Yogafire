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
    my @cmd = ('ssh', '-p', $ssh_port, '-i', $identity_file, '-l', $user, $instance->dns_name);
    print join(' ', @cmd), "\n";
    exec(join(' ', @cmd));
};

1;
