package Yogafire::InstanceTypes;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/list display_table find/;

my @instance_types = (
    { id => 't1.micro',    name => 'Micro Instance',                             cpu => '2ECU',        memory => '613MB',  io => 'Low', } ,
    { id => 'm1.small',    name => 'Small Instance',                             cpu => '1ECU x 1',    memory => '1.7GB',  io => 'Moderate', } ,
    { id => 'm1.medium',   name => 'Medium Instance',                            cpu => '2ECU x 1',    memory => '3.75GB', io => 'Moderate', } ,
    { id => 'm1.large',    name => 'Large Instance',                             cpu => '2ECU x 2',    memory => '7.5GB',  io => 'High', } ,
    { id => 'm1.xlarge',   name => 'Extra Large Instance',                       cpu => '2ECU x 4',    memory => '15GB',   io => 'High', } ,
    { id => 'm2.xlarge',   name => 'High-Memory Extra Large Instance',           cpu => '3.25ECU x 2', memory => '17.1GB', io => 'Moderate', } ,
    { id => 'm2.2xlarge',  name => 'High-Memory Double Extra Large Instance',    cpu => '3.25ECU x 4', memory => '34.2GB', io => 'High', } ,
    { id => 'm2.4xlarge',  name => 'High-Memory Quadruple Extra Large Instance', cpu => '3.25ECU x 8', memory => '68.4GB', io => 'High', } ,
    { id => 'c1.medium',   name => 'High-CPU Medium Instance',                   cpu => '2.5ECU x 2',  memory => '1.7GB',  io => 'Moderate', } ,
    { id => 'c1.xlarge',   name => 'High-CPU Extra Large Instance',              cpu => '2.5ECU x 8',  memory => '7GB',    io => 'High', } ,
    { id => 'cc1.4xlarge', name => 'Cluster Compute Quadruple Extra Large Instance', cpu => '2 x Intel Xeon X5570, quad-core “Nehalem” architecture',        memory => '23GB',   io => 'Very High', } ,
    { id => 'cc2.8xlarge', name => 'Cluster Compute Quadruple Extra Large Instance', cpu => '2 x Intel Xeon E5-2670, eight-core "Sandy Bridge" architecture',  memory => '60.5GB', io => 'Very High', } ,
    { id => 'cg1.4xlarge', name => 'Cluster GPU Quadruple Extra Large Instance'    , cpu => '2 x Intel Xeon X5570, quad-core “Nehalem” architecture',        memory => '22GB',   io => 'Very High', } ,
    { id => 'hi1.4xlarge', name => 'High I/O Quadruple Extra Large Instance'       , cpu => '4.4ECU x 8', memory => '60.5GB', io => 'Extremely high', } ,
);
use Text::ASCIITable;
use Term::ANSIColor qw/colored/;

sub list { \@instance_types; }

sub display_table {
    my @header = qw/id instance_name cpu memory io/;
    my $t = Text::ASCIITable->new();
    $t->setCols(@header);

    my $no = 0;
    for my $row (@instance_types) {
        $t->addRow([$row->{id}, $row->{name}, $row->{cpu}, $row->{memory}, $row->{io}]);
    }
    print $t;
}

sub find {
    my ($id) = @_;
    my @search = grep { /^$id$/ } @instance_types;
    return shift @search;
}

1;
