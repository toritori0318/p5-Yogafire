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

use Yogafire::Regions qw/list find display_table/;

sub abstract {'Show AWS Regions'}

sub execute {
    my ( $self, $opt, $args ) = @_;
    use Data::Dumper;
    my @regions  = $self->ec2->describe_regions();

    my @records;
    for my $region (@regions) {
        my $id     = $region->regionName;
        my $name   = find($id)->{name};
        my $record = { id => $id, name => $name };
        if($opt->{zones}) {
           $record->{zones} = [map { $_->zoneName } $region->zones];
        }
        push @records, $record;
    }

    display_table(\@records, $opt->{zones});
}

1;
