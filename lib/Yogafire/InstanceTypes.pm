package Yogafire::InstanceTypes;
use strict;
use warnings;
use Mouse;
has 'out_columns' => (
    is      => 'rw',
    default => sub { [qw/id name cpu memory io ebs_optimized instance_storage price price_month/] },
);
has 'out_format'     => ( is => 'rw' );
has 'instance_types' => ( is => 'rw' );
no Mouse;

use Yogafire::Regions;

my @instance_types = (
    {
        id               => 't2.micro',
        name             => 'T2 Micro Instance',
        name_tiny        => 't2 micro',
        cpu              => 'Variable(Credits/6)',
        ecu              => 'Variable',
        vcpu             => '1',
        memory           => '1GB',
        io               => 'Low to Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 't2.small',
        name             => 'T2 Small Instance',
        name_tiny        => 't2 small',
        cpu              => 'Variable(Credits/12)',
        ecu              => 'Variable',
        vcpu             => '1',
        memory           => '2GB',
        io               => 'Low to Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 't2.medium',
        name             => 'T2 Medium Instance',
        name_tiny        => 't2 medium',
        cpu              => 'Variable(Credits/24)',
        ecu              => 'Variable',
        vcpu             => '2',
        memory           => '4GB',
        io               => 'Low to Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 't2.large',
        name             => 'T2 Large Instance',
        name_tiny        => 't2 large',
        cpu              => 'Variable(Credits/36)',
        ecu              => 'Variable',
        vcpu             => '2',
        memory           => '8GB',
        io               => 'Low to Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 't1.micro',
        name             => 'Micro Instance',
        name_tiny        => 'micro',
        cpu              => 'Variable',
        ecu              => 'Variable',
        vcpu             => '1',
        memory           => '613MB',
        io               => 'Low',
        ebs_optimized    => 'N/A',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'm1.small',
        name             => 'Small Instance',
        name_tiny        => 'small',
        cpu              => '1 ECU(1 x 1core)',
        ecu              => '1',
        vcpu             => '1',
        memory           => '1.7GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '160 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'm1.medium',
        name             => 'Medium Instance',
        name_tiny        => 'medium',
        cpu              => '2 ECU(2 x 1core)',
        ecu              => '2',
        vcpu             => '1',
        memory           => '3.75GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '410 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'm1.large',
        name             => 'Large Instance',
        name_tiny        => 'large',
        cpu              => '4 ECU(2 x 2core)',
        ecu              => '4',
        vcpu             => '2',
        memory           => '7.5GB',
        io               => 'High',
        ebs_optimized    => '500 Mbps',
        instance_storage => '2 x 420 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'm1.xlarge',
        name             => 'Extra Large Instance',
        name_tiny        => 'extra large',
        cpu              => '8 ECU(2 x 4core)',
        ecu              => '8',
        vcpu             => '4',
        memory           => '15GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => '4 x 420 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'm3.medium',
        name             => 'M3 Medium Instance',
        name_tiny        => 'm3 medium',
        cpu              => '3 ECU(3.25 x 1core)',
        ecu              => '3',
        vcpu             => '1',
        memory           => '3.75GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 1 x 4 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm3.large',
        name             => 'M3 Large Instance',
        name_tiny        => 'm3 large',
        cpu              => '6.5 ECU(3.25 x 2core)',
        ecu              => '6.5',
        vcpu             => '2',
        memory           => '7.5GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 1 x 32 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm3.xlarge',
        name             => 'M3 Extra Large Instance',
        name_tiny        => 'm3 extra large',
        cpu              => '13 ECU(3.25 x 4core)',
        ecu              => '13',
        vcpu             => '4',
        memory           => '15GB',
        io               => 'Moderate',
        ebs_optimized    => '500 Mbps',
        instance_storage => 'SSD 2 x 40 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm3.2xlarge',
        name             => 'M3 Double Extra Large Instance',
        name_tiny        => 'm3 2extra large',
        cpu              => '26 ECU(3.25 x 8core)',
        ecu              => '26',
        vcpu             => '8',
        memory           => '30GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => 'SSD 2 x 80 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm4.large',
        name             => 'M4 Large Instance',
        name_tiny        => 'm4 large',
        cpu              => '6.5 ECU(3.25 x 2core)',
        ecu              => '6.5',
        vcpu             => '2',
        memory           => '8GB',
        io               => 'Moderate',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm4.xlarge',
        name             => 'M4 Extra Large Instance',
        name_tiny        => 'm4 extra large',
        cpu              => '13 ECU(3.25 x 4core)',
        ecu              => '13',
        vcpu             => '4',
        memory           => '16GB',
        io               => 'Moderate',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm4.2xlarge',
        name             => 'M4 Double Extra Large Instance',
        name_tiny        => 'm4 2extra large',
        cpu              => '26 ECU(3.25 x 8core)',
        ecu              => '26',
        vcpu             => '8',
        memory           => '32GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm4.4xlarge',
        name             => 'M4 Quadruple Extra Large Instance',
        name_tiny        => 'm4 4extra large',
        cpu              => '53.5 ECU(3.25 x 16core)',
        ecu              => '53.5',
        vcpu             => '16',
        memory           => '64GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm4.10xlarge',
        name             => 'M4 Ten Extra Large Instance',
        name_tiny        => 'm4 10extra large',
        cpu              => '124.5 ECU(3.25 x 40core)',
        ecu              => '124.5',
        vcpu             => '40',
        memory           => '160GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'r3.large',
        name             => 'R3 Large Instance',
        name_tiny        => 'r3 large',
        cpu              => '6.5 ECU(3.25 x 2core)',
        ecu              => '6.5',
        vcpu             => '2',
        memory           => '15',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 1 x 32 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'r3.xlarge',
        name             => 'R3 Extra Large Instance',
        name_tiny        => 'r3 extra large',
        cpu              => '13 ECU(3.25 x 4core)',
        ecu              => '13',
        vcpu             => '4',
        memory           => '30.5',
        io               => 'Moderate',
        ebs_optimized    => 'Yes',
        instance_storage => 'SSD 1 x 80 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'r3.2xlarge',
        name             => 'R3 Double Extra Large Instance',
        name_tiny        => 'r3 2extra large',
        cpu              => '26 ECU(3.25 x 8core)',
        ecu              => '26',
        vcpu             => '8',
        memory           => '61GB',
        io               => 'High',
        ebs_optimized    => 'Yes',
        instance_storage => 'SSD 1 x 160 GB',
        price            => 'N/A',
    },
    {
        id               => 'r3.4xlarge',
        name             => 'R3 Quadruple Extra Large Instance',
        name_tiny        => 'r3 4extra large',
        cpu              => '52 ECU(3.25 x 16core)',
        ecu              => '52',
        vcpu             => '16',
        memory           => '122',
        io               => 'High',
        ebs_optimized    => 'Yes',
        instance_storage => 'SSD 1 x 320 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'r3.8xlarge',
        name             => 'R3 Doubule Quadruple Extra Large Instance',
        name_tiny        => 'r3 8extra large',
        cpu              => '104 ECU(3.25 x 32core)',
        ecu              => '104',
        vcpu             => '32',
        memory           => '244',
        io               => '10 Gigabit',
        ebs_optimized    => 'Yes',
        instance_storage => 'SSD 2 x 320 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'm2.xlarge',
        name             => 'High-Memory Extra Large Instance',
        name_tiny        => 'high memory extra large',
        cpu              => '6.5 ECU(3.25 x 2core)',
        ecu              => '6.5',
        vcpu             => '2',
        memory           => '17.1GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '420 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'm2.2xlarge',
        name             => 'High-Memory Double Extra Large Instance',
        name_tiny        => 'high memory 2extra large',
        cpu              => '13 ECU(3.25 x 4core)',
        ecu              => '13',
        vcpu             => '4',
        memory           => '34.2GB',
        io               => 'High',
        ebs_optimized    => '500 Mbps',
        instance_storage => '850 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'm2.4xlarge',
        name             => 'High-Memory Quadruple Extra Large Instance',
        name_tiny        => 'high memory 4extra large',
        cpu              => '26 ECU(3.25 x 8core)',
        ecu              => '26',
        vcpu             => '8',
        memory           => '68.4GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => '2 x 840 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'c1.medium',
        name             => 'High-CPU Medium Instance',
        name_tiny        => 'high cpu medium',
        cpu              => '5 ECU(2.5 x 2core)',
        ecu              => '5',
        vcpu             => '2',
        memory           => '1.7GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '350 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'c1.xlarge',
        name             => 'High-CPU Extra Large Instance',
        name_tiny        => 'high cpu extra large',
        cpu              => '20 ECU(2.5 x 8core)',
        ecu              => '20',
        vcpu             => '8',
        memory           => '7GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => '4 x 420 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'c4.large',
        name             => 'High-CPU4 Large Instance',
        name_tiny        => 'high cpu4 large',
        cpu              => '8 ECU(4 x 2core)',
        ecu              => '8',
        vcpu             => '2',
        memory           => '3.75GB',
        io               => 'Moderate',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c4.xlarge',
        name             => 'High-CPU4 Extra Large Instance',
        name_tiny        => 'high cpu4 extra large',
        cpu              => '16 ECU(4 x 4core)',
        ecu              => '16',
        vcpu             => '4',
        memory           => '7GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c4.2xlarge',
        name             => 'High-CPU4 Double Extra Large Instance',
        name_tiny        => 'high cpu4 2extra large',
        cpu              => '31 ECU(4 x 8core)',
        ecu              => '31',
        vcpu             => '8',
        memory           => '15GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c4.4xlarge',
        name             => 'High-CPU4 Quadruple Extra Large Instance',
        name_tiny        => 'high cpu4 4extra large',
        cpu              => '62 ECU(4 x 16core)',
        ecu              => '62',
        vcpu             => '16',
        memory           => '30GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c4.8xlarge',
        name             => 'High-CPU4 Double Quadruple Extra Large Instance',
        name_tiny        => 'high cpu4 8extra large',
        cpu              => '132 ECU(4 x 36core)',
        ecu              => '132',
        vcpu             => '36',
        memory           => '60GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => 'N/A',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c3.large',
        name             => 'High-CPU3 Large Instance',
        name_tiny        => 'high cpu3 large',
        cpu              => '7 ECU(3.5 x 2core)',
        ecu              => '7',
        vcpu             => '2',
        memory           => '3.75GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 2 x 16 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c3.xlarge',
        name             => 'High-CPU3 Extra Large Instance',
        name_tiny        => 'high cpu3 extra large',
        cpu              => '14 ECU(3.5 x 4core)',
        ecu              => '14',
        vcpu             => '4',
        memory           => '7GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'SSD 2 x 40 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c3.2xlarge',
        name             => 'High-CPU3 Double Extra Large Instance',
        name_tiny        => 'high cpu3 2extra large',
        cpu              => '28 ECU(3.5 x 8core)',
        ecu              => '28',
        vcpu             => '8',
        memory           => '15GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'SSD 2 x 80 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c3.4xlarge',
        name             => 'High-CPU3 Quadruple Extra Large Instance',
        name_tiny        => 'high cpu3 4extra large',
        cpu              => '55 ECU(3.5 x 16core)',
        ecu              => '55',
        vcpu             => '16',
        memory           => '30GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'SSD 2 x 160 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'c3.8xlarge',
        name             => 'High-CPU3 Double Quadruple Extra Large Instance',
        name_tiny        => 'high cpu3 8extra large',
        cpu              => '108 ECU(3.5 x 32core)',
        ecu              => '108',
        vcpu             => '32',
        memory           => '60GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 2 x 320 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'cc2.8xlarge',
        name             => 'Cluster Compute Quadruple Extra Large Instance',
        name_tiny        => 'cluster compute 8extra large',
        cpu              => '88 ECU(2 x Intel Xeon E5-2670, 8core "Sandy Bridge" arch)',
        ecu              => '88',
        vcpu             => '32',
        memory           => '60.5GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => '4 x 840 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'cr1.8xlarge',
        name             => 'High Memory Cluster Eight Extra Large Instance',
        name_tiny        => 'high memory cluster 8extra large',
        cpu              => '88 ECU(2 x Intel Xeon E5-2670, 8core Intel Turbo, NUMA)',
        ecu              => '88',
        vcpu             => '32',
        memory           => '244GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 1 x 240 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'cg1.4xlarge',
        name             => 'Cluster GPU Quadruple Extra Large Instance',
        name_tiny        => 'cluster gpu 4extra large',
        cpu              => '33.5 ECU(2 x Intel Xeon X5570, 4core "Nehalem" arch)',
        ecu              => '33.5',
        vcpu             => '16',
        memory           => '22GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => '2 x 840 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'i2.large',
        name             => 'High-Storage Large Instance',
        name_tiny        => 'high storage large',
        cpu              => '7 ECU(3.5 x 2core)',
        ecu              => '7',
        vcpu             => '2',
        memory           => '15GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 2 x 360 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'i2.xlarge',
        name             => 'High-Storage Extra Large Instance',
        name_tiny        => 'high storage extra large',
        cpu              => '14 ECU(3.5 x 4core)',
        ecu              => '14',
        vcpu             => '4',
        memory           => '30.5GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'SSD 2 x 720 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'i2.2xlarge',
        name             => 'High-Storage Double Extra Large Instance',
        name_tiny        => 'high storage 2extra large',
        cpu              => '28 ECU(3.5 x 8core)',
        ecu              => '28',
        vcpu             => '8',
        memory           => '61GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'SSD 2 x 720 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'i2.4xlarge',
        name             => 'High-Storage Quadruple Extra Large Instance',
        name_tiny        => 'high storage 4extra large',
        cpu              => '55 ECU(3.5 x 16core)',
        ecu              => '55',
        vcpu             => '16',
        memory           => '122GB',
        io               => 'High',
        ebs_optimized    => 'YES',
        instance_storage => 'SSD 4 x 720 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'i2.8xlarge',
        name             => 'High-Storage Double Quadruple Extra Large Instance',
        name_tiny        => 'high storage 8extra large',
        cpu              => '108 ECU(3.5 x 32core)',
        ecu              => '108',
        vcpu             => '32',
        memory           => '244GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 8 x 720 GB',
        price            => 'N/A',
        previous_generation => 0,
    },
    {
        id               => 'hi1.4xlarge',
        name             => 'High I/O Quadruple Extra Large Instance',
        name_tiny        => 'high io 4extra large',
        cpu              => '35 ECU(2.2 x 16core)',
        ecu              => '35',
        vcpu             => '16',
        memory           => '60.5GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 2 x 1024 GB',
        price            => 'N/A',
        previous_generation => 1,
    },
    {
        id               => 'hs1.8xlarge',
        name             => 'High Storage Instances',
        name_tiny        => 'high storage instances',
        cpu              => '35 ECU(2.2 x 16core)',
        ecu              => '35',
        vcpu             => '16',
        memory           => '117GB',
        io               => '10 Gigabit',
        ebs_optimized    => 'N/A',
        instance_storage => '2T x 24',
        price            => 'N/A',
        previous_generation => 0,
    },
);

my $price_url_current  = 'https://a0.awsstatic.com/pricing/1/deprecated/ec2';
my $price_url_previous = 'https://a0.awsstatic.com/pricing/1/deprecated/ec2/previous-generation';
my %price_mapping = (
    'price-on-demand' => 'od',
    'price-ri-light'  => 'ri-light',
    'price-ri-medium' => 'ri-medium',
    'price-ri-heavy'  => 'ri-heavy',
);

use Yogafire::Output;
use Term::ANSIColor qw/colored/;
use Yogafire::Declare qw/ec2 config/;
use JSON;

sub BUILD {
    my ($self) = @_;
    $self->instance_types( \@instance_types );
}

sub get_prices {
    my ($self, $json_file) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(3);
    my $response = $ua->get($json_file);
    if ( $response->is_success ) {
        return JSON::decode_json( $response->decoded_content );    # or whatever
    } else {
        die $response->status_line;
    }
}

sub match_type_and_price_on_demand {
    my ($self, $prices, $os) = @_;
    my %types = map { $_->{id} => {} } @{$self->instance_types};
    for my $type (keys %types) {
        for my $price (@$prices) {
            for my $size (@{$price->{sizes}}) {
                next unless $size->{size} eq $type;

                my %h;
                for my $row (@{$size->{valueColumns}}) {
                    $h{$row->{name}} = $row->{'prices'}->{'USD'};
                }
                $types{$type}->{price} = $h{$os} || $h{'os'};
                if(!$types{$type}->{price} || $types{$type}->{price} eq 'N/A') {
                    $types{$type}->{price_month} = 'N/A';
                }else{
                    $types{$type}->{price_month} = $types{$type}->{price} * 24 * 30;
                }
            }
        }
    }
    return \%types;
}

sub match_type_and_price_reserved {
    my ($self, $prices, $os) = @_;
    my %types = map { $_->{id} => {} } @{$self->instance_types};
    for my $type (keys %types) {
        for my $price (@$prices) {
            for my $size (@{$price->{sizes}}) {
                next unless $size->{size} eq $type;

                my %h;
                for my $row (@{$size->{valueColumns}}) {
                    if($row->{name} =~ m/yrTerm1/) {
                        unless($h{yrTerm1}) {
                            $h{yrTerm1} = $row->{'prices'}->{'USD'};
                        } else {
                            $h{yrTerm1} .= " + " . $row->{'prices'}->{'USD'}."h";
                        }
                    }
                    if($row->{name} =~ m/yrTerm3/) {
                        unless($h{yrTerm3}) {
                            $h{yrTerm3} = $row->{'prices'}->{'USD'};
                        } else {
                            $h{yrTerm3} .= " + " . $row->{'prices'}->{'USD'} ."h";
                        }
                    }
                }
                for my $key (keys %h) {
                    my $hkey = "price_$key";
                    $types{$type}->{$hkey} = $h{$key};
                }
            }
        }
    }
    return \%types;
}

sub search {
    my ( $self, $opt ) = @_;
    my $region              = $opt->{region} || config->get('region');
    my $platform            = $opt->{platform} || 'linux';
    my $previous_generation = $opt->{'previous-generation'};
    my $price_on_demand     = $opt->{'price-od'};
    my $price_ri_light      = $opt->{'price-ri-light'};
    my $price_ri_medium     = $opt->{'price-ri-medium'};
    my $price_ri_heavy      = $opt->{'price-ri-heavy'};
    my $m_region            = Yogafire::Regions->new();
    my $cnv_region          = shift @{ [ grep { $_->regionName eq $region } @{$m_region->regions()} ] };

    my %prices = (
        price_od   => ($price_on_demand) ? $self->get_price_for_on_demand($cnv_region, $platform, 0) : {},
        price_ri_l => ($price_ri_light)  ? $self->get_price_for_reserved($cnv_region, $platform, 0, 'price-ri-light') : {},
        price_ri_m => ($price_ri_medium) ? $self->get_price_for_reserved($cnv_region, $platform, 0, 'price-ri-medium') : {},
        price_ri_h => ($price_ri_heavy)  ? $self->get_price_for_reserved($cnv_region, $platform, 0, 'price-ri-heavy') : {},
    );
    my %prices_previous_generation;
    if($previous_generation) {
        %prices_previous_generation = (
            price_od   => ($price_on_demand) ? $self->get_price_for_on_demand($cnv_region, $platform, 1) : {},
            price_ri_l => ($price_ri_light)  ? $self->get_price_for_reserved($cnv_region, $platform, 1, 'price-ri-light') : {},
            price_ri_m => ($price_ri_medium) ? $self->get_price_for_reserved($cnv_region, $platform, 1, 'price-ri-medium') : {},
            price_ri_h => ($price_ri_heavy)  ? $self->get_price_for_reserved($cnv_region, $platform, 1, 'price-ri-heavy') : {},
        );
    }

    my @convert_rows;
    for my $row (@{$self->instance_types}) {
        next if !$previous_generation && $row->{previous_generation};

        my %seed_prices = ($row->{previous_generation}) ? %prices_previous_generation : %prices;
        my $type = $row->{id};
        for my $pkey (keys %seed_prices) {
            my %p = %{$seed_prices{$pkey}};
            if(%p && $pkey eq "price_od") {
                $row->{price}       = $p{$type}->{price} || 'N/A';
                $row->{price_month} = $p{$type}->{price_month} || 'N/A';
            }
            if(%p && $pkey ne "price_od") {
                $row->{"${pkey}_yr1"} = $p{$type}->{price_yrTerm1} || 'N/A';
                $row->{"${pkey}_yr3"} = $p{$type}->{price_yrTerm3} || 'N/A';
            }
        }
        push @convert_rows, $row;
    }
    return \@convert_rows;
}

sub get_price_for_on_demand {
    my ( $self, $region, $platform, $previous_generation ) = @_;

    my $json_file  = $self->s3_json_file($platform, 'price-on-demand', $previous_generation);
    my $prices     = $self->get_prices($json_file);
    my $cnv_prices = shift @{ [ grep { $_->{region} eq $region->{data}->{oid} || $_->{region} eq $region->{data}->{regionName} } @{ $prices->{config}->{regions} } ] };

    return $self->match_type_and_price_on_demand($cnv_prices->{instanceTypes}, $platform);
}

sub get_price_for_reserved {
    my ( $self, $region, $platform, $previous_generation, $price_kind ) = @_;

    my $json_file  = $self->s3_json_file($platform, $price_kind, $previous_generation);
    my $prices     = $self->get_prices($json_file);
    my $cnv_prices = shift @{ [ grep { $_->{region} eq $region->{data}->{oid} || $_->{region} eq $region->{data}->{regionName} } @{ $prices->{config}->{regions} } ] };

    return $self->match_type_and_price_reserved($cnv_prices->{instanceTypes}, $platform);
}

sub s3_json_file {
    my ($self, $platform, $price_kind, $previous_generation) = @_;
    my $price_map = $price_mapping{$price_kind};
    die "[$price_kind] is invalid kindname." unless $price_map;

    if($previous_generation) {
        return "$price_url_previous/${platform}-${price_map}.json";
    } else {
        return "$price_url_current/${platform}-${price_map}.json";
    }
}

sub output {
    my ( $self, $rows, $opt ) = @_;

    # default column
    $self->out_columns([qw/id name_tiny ecu vcpu memory/]);

    # ex column
    push $self->out_columns, 'io'               if $opt->{'io'};
    push $self->out_columns, 'ebs_optimized'    if $opt->{'ebs-optimized'};
    push $self->out_columns, 'instance_storage' if $opt->{'instance-storage'};

    # price column
    push $self->out_columns, ('price', 'price_month') if $opt->{'price-od'};
    push $self->out_columns, ('price_ri_l_yr1', 'price_ri_l_yr3') if $opt->{'price-ri-light'};
    push $self->out_columns, ('price_ri_m_yr1', 'price_ri_m_yr3') if $opt->{'price-ri-medium'};
    push $self->out_columns, ('price_ri_h_yr1', 'price_ri_h_yr3') if $opt->{'price-ri-heavy'};

    my $output = Yogafire::Output->new( { format => $self->out_format } );
    $output->header( $self->out_columns );
    my @output_rows;
    for my $row (@$rows) {
        my $colored = $self->_get_group_color( $row->{id} );
        push @output_rows, [ map { $row->{$_} ? colored($row->{$_}, $colored) : $row->{$_} } @{$self->out_columns} ];
    }
    $output->output( \@output_rows );
}

sub _get_group_color {
    my ( $self, $id ) = @_;
    if ( $id =~ /^r3/ ) {
        return 'bold';
    } elsif ( $id =~ /^t2/ ) {
        return 'yellow';
    } elsif ( $id =~ /^m1/ ) {
        return 'green';
    } elsif ( $id =~ /^m4/ ) {
        return 'blue bold';
    } elsif ( $id =~ /^m3/ ) {
        return 'green bold';
    } elsif ( $id =~ /^m2/ ) {
        return 'blue bold';
    } elsif ( $id =~ /^c1/ ) {
        return 'cyan';
    } elsif ( $id =~ /^c4/ ) {
        return 'yellow';
    } elsif ( $id =~ /^c3/ ) {
        return 'blue';
    } elsif ( $id =~ /^cc/ ) {
        return 'magenta';
    } elsif ( $id =~ /^cg/ ) {
        return 'red';
    } elsif ( $id =~ /^hi/ ) {
        return 'red bold';
    } elsif ( $id =~ /^cr/ ) {
        return 'cyan bold';
    } elsif ( $id =~ /^hs/ ) {
        return 'magenta bold';
    } elsif ( $id =~ /^i2/ ) {
        return 'yellow bold';
    }
    return 'white';
}

1;
