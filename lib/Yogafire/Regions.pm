package Yogafire::Regions;
use strict;
use warnings;
use Mouse;
has 'out_columns' => (is => 'rw', default => sub { [qw/region_id region_name/] }, );
has 'out_format'  => (is => 'rw');
has 'regions'     => (is => 'rw');
no Mouse;

my @meta_regions = (
    { id => 'us-east-1',      oid => 'us-east',    name => 'US East (Northern Virginia)' },
    { id => 'us-west-1',      oid => 'us-west',    name => 'US West (Northern California)' },
    { id => 'us-west-2',      oid => 'us-west-2',  name => 'US West (Oregon)' },
    { id => 'eu-west-1',      oid => 'eu-ireland', name => 'EU (Ireland)' },
    { id => 'ap-southeast-1', oid => 'apac-sin',   name => 'Asia Pacific (Singapore)' },
    { id => 'ap-southeast-2', oid => 'apac-syd',   name => 'Asia Pacific (Sydney)' },
    { id => 'ap-northeast-1', oid => 'apac-tokyo', name => 'Asia Pacific (Tokyo)' },
    { id => 'sa-east-1',      oid => 'sa-east-1',  name => 'South America (Sao Paulo)' },
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
    for (@{$self->regions}) {
        if($text =~ /$_->regionName/) {
            return {
                id => $_->{id},
                name => $_->{name},
            };
        }
    }
    return {};
}

1;
