package Yogafire::Regions;
use strict;
use warnings;
use Mouse;
has 'out_columns' => (is => 'rw', default => sub { [qw/region_id region_name/] }, );
has 'out_format'  => (is => 'rw');
has 'regions'     => (is => 'rw');
no Mouse;

my @meta_regions = (
    { id => 'us-east-1',      oid => 'us-east-1',      name => 'US East (Northern Virginia)' },
    { id => 'us-east-2',      oid => 'us-east-2',      name => 'US East (Ohio)' },
    { id => 'us-west-1',      oid => 'us-west-1',      name => 'US West (Northern California)' },
    { id => 'us-west-2',      oid => 'us-west-2',      name => 'US West (Oregon)' },
    { id => 'eu-west-1',      oid => 'eu-west-1',      name => 'EU (Ireland)' },
    { id => 'eu-west-2',      oid => 'eu-west-2',      name => 'EU (London)' },
    { id => 'eu-central-1',   oid => 'eu-central-1',   name => 'EU (Frankfurt)' },
    { id => 'ca-central-1',   oid => 'ca-central-1',   name => 'Canada (Central)' },
    { id => 'ap-southeast-1', oid => 'ap-southeast-1', name => 'Asia Pacific (Singapore)' },
    { id => 'ap-southeast-2', oid => 'ap-southeast-2', name => 'Asia Pacific (Sydney)' },
    { id => 'ap-northeast-1', oid => 'ap-northeast-1', name => 'Asia Pacific (Tokyo)' },
    { id => 'ap-northeast-2', oid => 'ap-northeast-2', name => 'Asia Pacific (Seoul)' },
    { id => 'sa-east-1',      oid => 'sa-east-1',      name => 'South America (Sao Paulo)' },
    { id => 'ap-south-1',     oid => 'ap-south-1',     name => 'Asia Pacific (Munbai)' },
);

use Yogafire::Output;
use Term::ANSIColor qw/colored/;
use Yogafire::Declare qw/ec2 config/;

sub BUILD {
    my ($self) = @_;
    my @regions  = ec2->describe_regions();
    for my $region (@regions) {
        for my $meta_region (@meta_regions) {
            if($region->regionName eq $meta_region->{id}) {
                $region->{data}->{full_name} = $meta_region->{name};
                $region->{data}->{oid}       = $meta_region->{oid};
                last;
            }
        }
    }
    $self->regions(\@regions);
}

sub output {
    my ($self, $zones) = @_;
    my @headers = @{$self->out_columns};
    push @headers, 'region_zones' if $zones;

    my $output = Yogafire::Output->new({ format => $self->out_format });
    $output->header(\@headers);
    my @rows = @{$self->regions};
    @rows = map {
        my @data = ($_->regionName, $_->{data}->{full_name});
        if($zones) {
            my @zones = map { colored($_, $self->_get_state_color($_->zoneState)) } $_->zones;
            push @data, join(', ', @zones);
        }
        \@data;
    } @rows;
    $output->output(\@rows);
}

sub _get_state_color {
    my ($self, $status) = @_;
    if($status eq 'available') {
        return 'green';
    } else {
        return 'red';
    }
}

sub find {
    my ($self, $text) = @_;
    for my $region (@{$self->regions}) {
        my $region_id = $region->regionName;
        if($text =~ /$region_id/) {
            return {
                id   => $region_id,
                name => $region->{data}->{full_name},
            };
        }
    }
    return {};
}

1;
