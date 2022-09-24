package Yogafire::Command::Instance::ssmstarttmux;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has tagsname => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "n",
    documentation   => "specified instance tagsname.",
);
has filter => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "f",
    documentation   => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
);
has port => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "p",
    documentation   => "specified remort port number",
);
has localport => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "p",
    documentation   => "specified local port number",
);
has fuzzy => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "z",
    documentation => "Fuzzy host filter.",
);
has sync => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "enable synchronize-panes.",
);
has force => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "force execute.",
);
has fuzzy => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "z",
    documentation => "Fuzzy host filter.",
);
no Mouse;

use Yogafire::CommandClass::InstanceProc;

sub abstract {'Login to ec2 using system session manager by tmux'}

sub command_names {'ssm-start-tmux'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga ssm-start-tmux [-?] <tagsname>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $proc = Yogafire::CommandClass::InstanceProc->new(
        {
            action       => 'ssmstarttmux',
            opt          => $opt,
            force        => $opt->{force},
            interactive  => 1,
            multi        => 1,
            loop         => $opt->{loop},
        }
    );
    if($opt->{self}) {
        $proc->self_process();
    } else {
        my $host = $args->[0];
        # fuzzy finder
        $host = "*${host}*" if $host && $opt->{fuzzy};
        $opt->{host} = $host if $host;

        $proc->action_process();
    }
}

1;
