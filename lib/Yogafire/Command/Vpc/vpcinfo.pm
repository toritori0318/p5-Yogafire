package Yogafire::Command::Vpc::vpcinfo;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

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
            interactive  => 1,
            loop         => $opt->{loop},
        }
    );
    my $host = $args->[0];
    $opt->{host} = $host if $host;
    $proc->action_process();
}

1;
