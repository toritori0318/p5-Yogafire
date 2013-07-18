package Yogafire::Instance::Action::SSHTmux;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'sshtmux');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running/],
    },
);
no Mouse;

use Yogafire::Instance qw/list/;
use Yogafire::CommandClass::SSH;

sub procs {
    my ($self, $instances, $opt) = @_;
    $self->_procs($instances, $opt);
}

sub proc {
    my ($self, $instance, $opt) = @_;
    $self->_procs([$instance], $opt);
}

sub _procs {
    my ($self, $instances, $opt) = @_;

    my @ssh_commands;
    for my $instance (@$instances) {
        my $yoga_ssh = Yogafire::CommandClass::SSH->new(
            {
                opt    => $opt,
            }
        );
        my $ssh_cmd = $yoga_ssh->build_raw_ssh_command($instance);
        if(scalar @ssh_commands == 0) {
            push @ssh_commands, sprintf('tmux new-window -n "yoga" "%s" ', $ssh_cmd);
        } else {
            push @ssh_commands, sprintf(" tmux split-window '%s' && tmux select-layout 'tile' ", $ssh_cmd);
        }
    }

    my $tmux_ssh_command = join("&&", @ssh_commands);
    #print "$tmux_ssh_command\n";
    exec($tmux_ssh_command);
};

1;

