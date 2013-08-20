package Yogafire::Command::Vpc::vpcgraph;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has 'graph-format' => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "f",
    documentation   => "specified output graph format(default:ascii). (ascii / boxart)",
);
has loop => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "l",
    documentation   => "Repeat without exit interactive mode.",
);
has 'route-table' => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "R",
    documentation   => "Enable route table graph.",
);
has 'internet-gateway' => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "I",
    documentation   => "Enable internet gateway graph.",
);
has detail => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "D",
    documentation   => "Enable detail info.",
);
no Mouse;

use Yogafire::CommandClass::VpcProc;

sub abstract {'VPC Graph View'}
sub command_names {'vpc-graph'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga vpc-graph [-?] <tagsname>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $proc = Yogafire::CommandClass::VpcProc->new(
        {
            action       => 'graph',
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
