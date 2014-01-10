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
use Yogafire::CommandClass::SSH;

sub proc {
    my ($self, $instance, $opt) = @_;

    my $yoga_ssh = Yogafire::CommandClass::SSH->new(
        {
            opt    => $opt,
        }
    );
    my $ssh_cmd = $yoga_ssh->build_raw_ssh_command($instance);
    $self->exec_ssh($ssh_cmd) unless $opt->{retry};

    # retry
    my $host = $yoga_ssh->target_host($instance);
    while (1) {
        # check ssh connection
        eval { $yoga_ssh->ssh({ host => $host }); };
        $self->exec_ssh($ssh_cmd) unless $@;

        #warn $@;
        sleep 10;
    }
};

sub exec_ssh {
    my ($self, $ssh_cmd) = @_;
    print "$ssh_cmd\n";
    exec($ssh_cmd);
}

1;
