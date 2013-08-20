package Yogafire::Command::Plugin::region;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has 'zones' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Add display item the availability zone.",
);
no Mouse;

use Yogafire::Regions;

sub abstract {'Show AWS Regions'}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $yoga_regions = Yogafire::Regions->new();
    $yoga_regions->output($opt->{zones});
}

1;
