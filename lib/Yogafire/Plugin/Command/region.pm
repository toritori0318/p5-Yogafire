package Yogafire::Plugin::Command::region;
use Mouse;
extends qw(Yogafire::CommandBase);
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

    my $yoga_regions = Yogafire::Regions->new({ ec2 => $self->ec2 });
    $yoga_regions->output($opt->{zones});
}

1;
