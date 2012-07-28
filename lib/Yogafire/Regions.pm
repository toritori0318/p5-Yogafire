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
    { id => 'ap-northeast-1', name => 'Asia Pacific (Tokyo)' },
    { id => 'sa-east-1',      name => 'South America (Sao Paulo)' },
);

use Text::ASCIITable;
use Term::ANSIColor qw/colored/;

sub list { \@regions; }

sub display_table {
    my @header = qw/region_id region_name/;
    my $t = Text::ASCIITable->new();
    $t->setCols(@header);

    my $no = 0;
    for my $row (@regions) {
        $t->addRow([$row->{id}, $row->{name}]);
    }
    print $t;
}

sub find {
    my ($id) = @_;
    my @search = grep { /^$id$/ } @regions;
    return shift @search;
}

1;
