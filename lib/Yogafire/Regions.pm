package Yogafire::Regions;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/list display_table find/;

my @regions = (
    { id => 'us-east-1',      name => 'US East (Northern Virginia)' },
    { id => 'us-west-1',      name => 'US West (Northern California)' },
    { id => 'us-west-2',      name => 'US West (Oregon)' },
    { id => 'eu-west-1',      name => 'EU (Ireland)' },
    { id => 'ap-southeast-1', name => 'Asia Pacific (Singapore)' },
    { id => 'ap-southeast-2', name => 'Asia Pacific (Sydney)' },
    { id => 'ap-northeast-1', name => 'Asia Pacific (Tokyo)' },
    { id => 'sa-east-1',      name => 'South America (Sao Paulo)' },
);

use Text::ASCIITable;
use Term::ANSIColor qw/colored/;

sub list { \@regions; }

sub display_table {
    my ($rows, $zones) = @_;
    my @header = qw/region_id region_name/;
    push @header, 'region_zones' if $zones;
    my $t = Text::ASCIITable->new();
    $t->setCols(@header);

    my $no = 0;
    for my $row (@$rows) {
        my @data = ($row->{id}, $row->{name});
        push @data, join(',', @{$row->{zones}}) if $zones;
        $t->addRow(\@data);
    }
    print $t;
}

sub find {
    my ($id) = @_;
    my @search = grep { $_->{id} =~ /^$id$/ } @regions;
    return shift @search;
}

1;
