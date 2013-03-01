package Yogafire::Command::expandvolume;
use Mouse;

extends qw(Yogafire::CommandBase);

has state => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "s",
    documentation => "specified instance status (running / stopped)",
);
has filter => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
);
has force => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "force execute.",
);
has tagsname => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "n",
    documentation   => "specified instance tagsname.",
);
has size => (
    traits          => [qw(Getopt)],
    isa             => "Int",
    is              => "rw",
    documentation   => "specified update size(GB).",
);
has availability_zone => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    documentation   => "specified availability zone.(default: The same as the instance)",
);
has loop => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "l",
    documentation   => "Repeat without exit interactive mode.",
);
no Mouse;

use Yogafire::CommandClass::InstanceProc;

sub abstract {'EC2 Expand Volume'}
sub command_names {'expand-volume'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga expand-volume [-?] <tagsname>';
    $self->{usage};
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "--size is required.\n\n" . $self->usage
        if $opt->{force} && !$opt->{size};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $proc = Yogafire::CommandClass::InstanceProc->new(
        {
            action       => 'expandvolume',
            ec2          => $self->ec2,
            config       => $self->config,
            opt          => $opt,
            force        => $opt->{force},
            interactive  => 1,
            loop         => $opt->{loop},
        }
    );
    if($opt->{self}) {
        $proc->self_process();
    } else {
        my $tagsname = $args->[0];
        $opt->{tagsname} = $tagsname if $tagsname;
        $proc->action_process();
    }
}

1;
