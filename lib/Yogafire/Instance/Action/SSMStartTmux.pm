package Yogafire::Instance::Action::SSMStartTmux;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'ssmstarttmux');
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
use POSIX qw(strftime);

sub build_ssm_start_session_command {
    my ($self, $instance) = @_;

    my $access_key = sprintf("AWS_ACCESS_KEY_ID=%s", $instance->aws->access_key || '');
    my $secret_key = sprintf("AWS_SECRET_ACCESS_KEY=%s", $instance->aws->secret || '');
    my $session_token = sprintf("AWS_SESSION_TOKEN=%s", $instance->aws->security_token || '');
    my $region = sprintf("AWS_DEFAULT_REGION=%s", $instance->aws->region || '');

    my @cmd = ($access_key, $secret_key, $session_token, $region, 'aws', 'ssm', 'start-session', '--target', $instance->instanceId);
    return join(' ', @cmd);
}

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
    $instances = [$instances] if ref($instances) ne 'ARRAY';

    my @ssh_commands;
    for my $instance (@$instances) {
        my $ssh_cmd = $self->build_ssm_start_session_command($instance);
        if(scalar @ssh_commands == 0) {
            push @ssh_commands, sprintf('tmux new-window -n "yoga-ssh-win" "%s"', $ssh_cmd);
        } else {
            push @ssh_commands, sprintf("tmux split-window '%s' && tmux select-layout 'tile'", $ssh_cmd);
        }
    }

    if($opt->{sync}) {
        push @ssh_commands, sprintf("tmux set-window-option synchronize-panes on");
    }

    my $session = '';
    if($ENV{SESSION_NAME}) {
        $session=$ENV{SESSION_NAME};
    } else {
        my $datetime = strftime("%Y%m%d%H%M%S", localtime());
        $session="yoga-ssh-$datetime";
    }

    # start tmux session
    system("tmux new-session -d -n yoga-ssh-tmux -s $session");

    # exec tmux attach
    push @ssh_commands, "tmux select-pane -t 1";
    push @ssh_commands, "tmux attach-session -t $session";
    my $tmux_ssh_command = join(" && ", @ssh_commands);
    exec($tmux_ssh_command);
};


1;
