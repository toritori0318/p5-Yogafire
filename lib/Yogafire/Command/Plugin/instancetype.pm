package Yogafire::Command::Plugin::instancetype;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has detail => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "D",
    documentation => "detail view.",
);
has platform => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "p",
    documentation => "specify the platform .(linux / mswin  default:linux)",
);
has 'io' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show the network io.(default: off)",
);
has 'ebs-optimized' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show the ebs optimized.(default: off)",
);
has 'instance-storage' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show the instance storage.(default: off)",
);
has 'price-od' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    default       => sub { 1 },
    documentation => "Show the on-demand price.(default: on)",
);
has 'price-ri-light' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show the reserved-instance-light price.(default: off)",
);
has 'price-ri-medium' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show the reserved-instance-medium price.(default: off)",
);
has 'price-ri-heavy' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show the reserved-instance-heavy price.(default: off)",
);
has 'previous-generation' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "g",
    documentation => "Show the previous-generation type.(default: off)",
);
#has filter => (
#    traits          => [qw(Getopt)],
#    isa             => "Str",
#    is              => "rw",
#    cmd_aliases     => "f",
#    documentation   => "api filter. (ex.--filter='group=m1,price>0.130')",
#);
no Mouse;

sub abstract {'Show Instance Types'}

sub command_names {'instance-type'}

sub execute {
    my ( $self, $opt, $args ) = @_;

    $opt->{'price-od'} = 1 unless defined $opt->{'price-od'};

    my $y_instance_types = Yogafire::InstanceTypes->new();
    my $rows = $y_instance_types->search($opt);
    $y_instance_types->output($rows, $opt);
}

1;
