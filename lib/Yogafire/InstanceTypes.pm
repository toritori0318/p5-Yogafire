package Yogafire::InstanceTypes;
use strict;
use warnings;
use Mouse;
has 'out_columns'    => (is => 'rw', default => sub { [qw/id instance_name cpu memory io price/] }, );
has 'out_format'     => (is => 'rw');
has 'instance_types' => (is => 'rw');
no Mouse;

my @instance_types = (
    { id => 't1.micro',    name => 'Micro Instance',                                 cpu => '2ECU',        memory => '613MB',  io => 'Low',      price => '0.027', } ,
    { id => 'm1.small',    name => 'Small Instance',                                 cpu => '1ECU x 1',    memory => '1.7GB',  io => 'Moderate', price => '0.088', } ,
    { id => 'm1.medium',   name => 'Medium Instance',                                cpu => '2ECU x 1',    memory => '3.75GB', io => 'Moderate', price => '0.175', } ,
    { id => 'm1.large',    name => 'Large Instance',                                 cpu => '2ECU x 2',    memory => '7.5GB',  io => 'High',     price => '0.350', } ,
    { id => 'm1.xlarge',   name => 'Extra Large Instance',                           cpu => '2ECU x 4',    memory => '15GB',   io => 'High',     price => '0.700', } ,
    { id => 'm3.xlarge',   name => 'M3 Extra Large Instance',                        cpu => '3.25ECU x 4', memory => '15GB',   io => 'Moderate', price => '0.760', } ,
    { id => 'm3.2xlarge',  name => 'M3 Double Extra Large Instance',                 cpu => '3.25ECU x 8', memory => '30GB',   io => 'High',     price => '1.520', } ,
    { id => 'm2.xlarge',   name => 'High-Memory Extra Large Instance',               cpu => '3.25ECU x 2', memory => '17.1GB', io => 'Moderate', price => '0.505', } ,
    { id => 'm2.2xlarge',  name => 'High-Memory Double Extra Large Instance',        cpu => '3.25ECU x 4', memory => '34.2GB', io => 'High',     price => '1.010', } ,
    { id => 'm2.4xlarge',  name => 'High-Memory Quadruple Extra Large Instance',     cpu => '3.25ECU x 8', memory => '68.4GB', io => 'High',     price => '2.020', } ,
    { id => 'c1.medium',   name => 'High-CPU Medium Instance',                       cpu => '2.5ECU x 2',  memory => '1.7GB',  io => 'Moderate', price => '0.185', } ,
    { id => 'c1.xlarge',   name => 'High-CPU Extra Large Instance',                  cpu => '2.5ECU x 8',  memory => '7GB',    io => 'High',     price => '0.740', } ,
    { id => 'cc1.4xlarge', name => 'Cluster Compute Quadruple Extra Large Instance', cpu => '2 x Intel Xeon X5570, quad-core "Nehalem" arch',          memory => '23GB',   io => 'Very High', price => '-', } ,
    { id => 'cc2.8xlarge', name => 'Cluster Compute Quadruple Extra Large Instance', cpu => '2 x Intel Xeon E5-2670, eight-core "Sandy Bridge" arch',  memory => '60.5GB', io => 'Very High', price => '-', } ,
    { id => 'cg1.4xlarge', name => 'Cluster GPU Quadruple Extra Large Instance'    , cpu => '2 x Intel Xeon X5570, quad-core "Nehalem" arch',          memory => '22GB',   io => 'Very High', price => '-', } ,
    { id => 'hi1.4xlarge', name => 'High I/O Quadruple Extra Large Instance'       , cpu => '4.4ECU x 8', memory => '60.5GB', io => 'Extremely high', price => '-', } ,
);

use Yogafire::Output;
use Term::ANSIColor qw/colored/;

sub BUILD {
    my ($self) = @_;
    $self->instance_types(\@instance_types);
}

sub output {
    my ($self, $zones) = @_;
    my $output = Yogafire::Output->new({ format => $self->out_format });
    $output->header($self->out_columns);
    my @rows = @{$self->instance_types};
    @rows = map {
        [
            colored($_->{id}, $self->_get_group_color($_->{id})),
            $_->{name},
            $_->{cpu},
            $_->{memory},
            $_->{io},
            $_->{price},
        ]
    } @rows;
    $output->output(\@rows);
}

sub _get_group_color {
    my ($self, $id) = @_;
    if($id =~ /^t1/) {
        return 'bold';
    } elsif($id =~ /^m1/) {
        return 'green';
    } elsif($id =~ /^m3/) {
        return 'yellow';
    } elsif($id =~ /^m2/) {
        return 'blue';
    } elsif($id =~ /^c1/) {
        return 'cyan';
    } elsif($id =~ /^cc/) {
        return 'magenta';
    } elsif($id =~ /^cg/) {
        return 'red';
    } elsif($id =~ /^hi/) {
        return 'red bold';
    }
}

1;
