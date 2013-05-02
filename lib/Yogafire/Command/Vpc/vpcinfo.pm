package Yogafire::Command::Vpc::vpcinfo;
use Mouse;

extends qw(Yogafire::CommandBase);

has interactive => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "i",
    documentation   => "interactive mode.",
);
has state => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "s",
    documentation   => "specified instance status (running / stopped)",
);
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
has format => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "specified output format(default:table). (table / plain / json)",
);
has loop => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "l",
    documentation   => "Repeat without exit interactive mode.",
);
no Mouse;

use Yogafire::CommandClass::VpcProc;

sub abstract {'VPC List vpcs'}
sub command_names {'vpc-info'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga vpc-info [-?] <tagsname>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $proc = Yogafire::CommandClass::VpcProc->new(
        {
            action       => 'info',
            opt          => $opt,
            interactive  => $opt->{interactive},
            loop         => $opt->{loop},
        }
    );
    my $host = $args->[0];
    $opt->{host} = $host if $host;
    $proc->action_process();
}

1;
