package Yogafire::Command::Plugin::instancetype;
use Mouse;
extends qw(Yogafire::CommandBase);
no Mouse;

use Yogafire::InstanceTypes;

sub abstract {'Show Instance Types'}

sub command_names {'instance-type'}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $y_instance_types = Yogafire::InstanceTypes->new({ ec2 => $self->ec2 });
    $y_instance_types->output();
}

1;
