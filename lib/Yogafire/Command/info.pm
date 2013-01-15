package Yogafire::Command::info;
use Mouse;
use Mouse::Util::TypeConstraints;

extends qw(Yogafire::CommandBase);

has state => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "s",
    documentation => "specified instance status (running / stopped)",
);
has tagsname => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "n",
    documentation   => "specified instance tagsname.",
);
has filter => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
);
has loop => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "l",
    documentation   => "Repeat without exit interactive mode.",
);
no Mouse;

sub abstract {'EC2 Instance Infomation'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga info [-?] <tagsname>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $tagsname = $args->[0];
    $opt->{tagsname} = $tagsname if $tagsname;

    $self->action_process('info', $opt);
}

1;
