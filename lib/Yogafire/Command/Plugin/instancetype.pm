package Yogafire::Command::Plugin::instancetype;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has region => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "r",
    documentation => "specify the region name.",
);
has 'view-detail' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "F",
    documentation => "specify the region name.",
);
has platform => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "p",
    documentation => "specify the platform .(linux / mswin  default:linux)",
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

    my $y_instance_types = Yogafire::InstanceTypes->new();
    my $rows = $y_instance_types->search($opt);
    $y_instance_types->output($rows, $opt);
}

1;
