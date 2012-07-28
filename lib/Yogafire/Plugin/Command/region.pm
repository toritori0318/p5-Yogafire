package Yogafire::Plugin::Command::region;
use Mouse;

extends qw(Yogafire::Command Yogafire::CommandAttribute);

no Mouse;

use Yogafire::Regions qw/list display_table/;

sub abstract {'Show AWS Regions'}

sub execute {
    my ( $self, $opt, $args ) = @_;

    display_table();
}

1;
