package Yogafire::Command::Instance::dockerps;
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
has user => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "u",
    documentation   => "specified login user",
);
has identity_file => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "i",
    documentation   => "specified identity file",
);
has port => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "p",
    documentation   => "specified port number",
);
has proxy => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    documentation   => "specified proxy server name(ip or dns or instance_id or tagsname).",
);
has retry => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "s",
    documentation => "Retry until ssh succeeds.",
);
has fuzzy => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "z",
    documentation => "Fuzzy host filter.",
);
has 'docker-container-filter' => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "df",
    documentation => "Docker container filter.",
);
no Mouse;

use Yogafire::CommandClass::InstanceProc;

sub abstract {'EC2 Docker ps'}

sub command_names {'docker-ps'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga docker-ps [-?] <tagsname>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    $opt->{"docker_command"} = "ps";
    my $proc = Yogafire::CommandClass::InstanceProc->new(
        {
            action       => 'docker',
            opt          => $opt,
            force        => $opt->{force},
            interactive  => 1,
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
