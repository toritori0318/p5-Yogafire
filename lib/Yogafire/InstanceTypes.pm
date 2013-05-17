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
        id               => 't1.micro',
        oid              => 'uODI_u',
        name             => 'Micro Instance',
        cpu              => '2 ECU(burst)',
        memory           => '613MB',
        io               => 'Low',
        ebs_optimized    => 'N/A',
        instance_storage => 'N/A',
        price            => 'N/A',
    },
    {
        id               => 'm1.small',
        oid              => 'stdODI_sm',
        name             => 'Small Instance',
        cpu              => '1 ECU(1 x 1core)',
        memory           => '1.7GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '160 GB',
        price            => 'N/A',
    },
    {
        id               => 'm1.medium',
        oid              => 'stdODI_med',
        name             => 'Medium Instance',
        cpu              => '2 ECU(2 x 1core)',
        memory           => '3.75GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '410 GB',
        price            => 'N/A',
    },
    {
        id               => 'm1.large',
        oid              => 'stdODI_lg',
        name             => 'Large Instance',
        cpu              => '4 ECU(2 x 2core)',
        memory           => '7.5GB',
        io               => 'High',
        ebs_optimized    => '500 Mbps',
        instance_storage => '850 GB',
        price            => 'N/A',
    },
    {
        id               => 'm1.xlarge',
        oid              => 'stdODI_xl',
        name             => 'Extra Large Instance',
        cpu              => '8 ECU(2 x 4core)',
        memory           => '15GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => '1690 GB',
        price            => 'N/A',
    },
    {
        id               => 'm3.xlarge',
        oid              => 'secgenstdODI_xl',
        name             => 'M3 Extra Large Instance',
        cpu              => '13 ECU(3.25 x 4core)',
        memory           => '15GB',
        io               => 'Moderate',
        ebs_optimized    => '500 Mbps',
        instance_storage => 'N/A',
        price            => 'N/A',
    },
    {
        id               => 'm3.2xlarge',
        oid              => 'secgenstdODI_xxl',
        name             => 'M3 Double Extra Large Instance',
        cpu              => '26 ECU(3.25 x 8core)',
        memory           => '30GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => 'N/A',
        price            => 'N/A',
    },
    {
        id               => 'm2.xlarge',
        oid              => 'hiMemODI_xl',
        name             => 'High-Memory Extra Large Instance',
        cpu              => '6.5 ECU(3.25 x 2core)',
        memory           => '17.1GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '420 GB',
        price            => 'N/A',
    },
    {
        id               => 'm2.2xlarge',
        oid              => 'hiMemODI_xxl',
        name             => 'High-Memory Double Extra Large Instance',
        cpu              => '13 ECU(3.25 x 4core)',
        memory           => '34.2GB',
        io               => 'High',
        ebs_optimized    => '500 Mbps',
        instance_storage => '850 GB',
        price            => 'N/A',
    },
    {
        id               => 'm2.4xlarge',
        oid              => 'hiMemODI_xxxxl',
        name             => 'High-Memory Quadruple Extra Large Instance',
        cpu              => '26 ECU(3.25 x 8core)',
        memory           => '68.4GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => '1690 GB',
        price            => 'N/A',
    },
    {
        id               => 'c1.medium',
        oid              => 'hiCPUODI_med',
        name             => 'High-CPU Medium Instance',
        cpu              => '5 ECU(2.5 x 2core)',
        memory           => '1.7GB',
        io               => 'Moderate',
        ebs_optimized    => 'N/A',
        instance_storage => '350 GB',
        price            => 'N/A',
    },
    {
        id               => 'c1.xlarge',
        oid              => 'hiCPUODI_xl',
        name             => 'High-CPU Extra Large Instance',
        cpu              => '20 ECU(2.5 x 8core)',
        memory           => '7GB',
        io               => 'High',
        ebs_optimized    => '1000 Mbps',
        instance_storage => '1690 GB',
        price            => 'N/A',
    },
    {
        id               => 'cc2.8xlarge',
        oid              => 'clusterComputeI_xxxxxxxxl',
        name             => 'Cluster Compute Quadruple Extra Large Instance',
        cpu              => '88 ECU(2 x Intel Xeon E5-2670, 8core "Sandy Bridge" arch)',
        memory           => '60.5GB',
        io               => 'Very High',
        ebs_optimized    => 'N/A',
        instance_storage => '3370 GB',
        price            => 'N/A',
    },
    {
        id               => 'cr1.8xlarge',
        oid              => 'clusterHiMemODI_xxxxxxxxl',
        name             => 'High Memory Cluster Eight Extra Large Instance',
        cpu              => '88 ECU(2 x Intel Xeon E5-2670, 8core Intel Turbo, NUMA)',
        memory           => '244GB',
        io               => 'Extremely high',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSD 240 GB',
        price            => 'N/A',
    },
    {
        id               => 'cg1.4xlarge',
        oid              => 'clusterGPUI_xxxxl',
        name             => 'Cluster GPU Quadruple Extra Large Instance',
        cpu              => '33.5 ECU(2 x Intel Xeon X5570, 4core "Nehalem" arch)',
        memory           => '22GB',
        io               => 'Very High',
        ebs_optimized    => 'N/A',
        instance_storage => '1690 GB',
        price            => 'N/A',
    },
    {
        id               => 'hi1.4xlarge',
        oid              => 'hiIoODI_xxxxl',
        name             => 'High I/O Quadruple Extra Large Instance',
        cpu              => '35 ECU(2.2 x 16core)',
        memory           => '60.5GB',
        io               => 'Extremely high',
        ebs_optimized    => 'N/A',
        instance_storage => 'SSDx2 1024 GB',
        price            => 'N/A',
    },
    {
        id               => 'hs1.8xlarge',
        oid              => 'hiStoreODI_xxxxxxxxl',
        name             => 'High Storage Instances',
        cpu              => '35 ECU(2.2 x 16core)',
        memory           => '117GB',
        io               => 'Extremely high',
        ebs_optimized    => 'N/A',
        instance_storage => '2T x 24',
        price            => 'N/A',
    },
);

my $s3_json = 'http://aws.amazon.com/jp/ec2/pricing/pricing-on-demand-instances.json/';

use Yogafire::Output;
use Term::ANSIColor qw/colored/;
use Yogafire::Declare qw/ec2 config/;
use JSON;

sub BUILD {
    my ($self) = @_;
    $self->instance_types( \@instance_types );
}

sub get_prices {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(3);
    my $response = $ua->get($s3_json);
    if ( $response->is_success ) {
        return JSON::decode_json( $response->decoded_content );    # or whatever
    } else {
        die $response->status_line;
    }
}

sub get_region_price {
    my ($self, $region) = @_;
    my $prices = $self->get_prices();
    my $m_region = Yogafire::Regions->new();
    my $cnv_region   = shift @{ [ grep { $_->regionName eq $region } @{$m_region->regions()} ] };
    my $region_price = shift @{ [ grep { $_->{region} eq $cnv_region->{data}->{oid} } @{ $prices->{config}->{regions} } ] };
    return $region_price;
}

sub match_type_and_price {
    my ($self, $types, $prices, $os) = @_;
    for my $type (@$types) {
        my ($group, $tiny_type) = split /_/, $type->{oid};
        for my $price (@$prices) {
            next unless $price->{type} eq $group;

            for my $size (@{$price->{sizes}}) {
                next unless $size->{size} eq $tiny_type;

                my %h;
                for my $row (@{$size->{valueColumns}}) {
                    $h{$row->{name}} = $row->{'prices'}->{'USD'};
                }
                $type->{price}       = $h{$os};
                if($type->{price} eq 'N/A') {
                     $type->{price_month} = 'N/A';
                }else{
                     $type->{price_month} = $h{$os} * 24 * 30;
                }
            }
        }
    }
    return $types;
}

sub search {
    my ( $self, $opt ) = @_;
    my $region   = $opt->{region} || config->get('region');
    my $platform = $opt->{platform} || 'linux';

    my $prices = $self->get_region_price($region);
    my $convert_rows = $self->match_type_and_price($self->instance_types, $prices->{instanceTypes}, $platform);
    return $convert_rows;
}

sub output {
    my ( $self, $rows, $opt ) = @_;

    if($opt->{'view-detail'}) {
        $self->out_columns([qw/id name cpu memory io ebs_optimized instance_storage price price_month/]);
    } else {
        $self->out_columns([qw/id name cpu memory io price/]);
    }

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
    if ( $id =~ /^t1/ ) {
        return 'bold';
    } elsif ( $id =~ /^m1/ ) {
        return 'green';
    } elsif ( $id =~ /^m3/ ) {
        return 'yellow';
    } elsif ( $id =~ /^m2/ ) {
        return 'blue';
    } elsif ( $id =~ /^c1/ ) {
        return 'cyan';
    } elsif ( $id =~ /^cc/ ) {
        return 'magenta';
    } elsif ( $id =~ /^cg/ ) {
        return 'red';
    } elsif ( $id =~ /^hi/ ) {
        return 'red bold';
    } elsif ( $id =~ /^cr/ ) {
        return 'blue bold';
    } elsif ( $id =~ /^hs/ ) {
        return 'magenta bold';
    }
}

1;
