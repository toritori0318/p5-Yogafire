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
has 'price-kind' => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "k",
    documentation => "specify the price kind .(on-demand / reserved-right / reserved-medium / reserved-heavy default:on-demand)",
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
