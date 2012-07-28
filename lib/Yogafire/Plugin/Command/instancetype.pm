package Yogafire::Plugin::Command::instancetype;
use Mouse;

extends qw(Yogafire::Command Yogafire::CommandAttribute);

no Mouse;

use Yogafire::InstanceTypes qw/list display_table/;

sub abstract {'Show Instance Types'}

sub command_names {'instance-type'}

sub execute {
    my ( $self, $opt, $args ) = @_;

    display_table();
}

1;
