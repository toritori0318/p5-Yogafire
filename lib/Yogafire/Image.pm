package Yogafire::Image;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw/list display_list display_table convert_row/;

use Text::ASCIITable;
use Term::ANSIColor qw/colored/;

sub list {
    my ($ec2, $opts) = @_;
    $opts ||= {};

    my $owner_id     = ($opts->{owner_id}) ? $opts->{owner_id} : '';
    my $state        = $opts->{state};
    my $name         = $opts->{name} || '';
    my $tagsname     = $opts->{tagsname} || '';
    my $customfilter = $opts->{filter} || '';
    my @filters = ();
    for (split /,/, $customfilter) {
        my ($key, $value) = split /=/, $_;
        push @filters, { $key => $value };
    }

    # filter
    my %filter = ();
    $filter{'state'}    = $state    if $state;
    $filter{'tag:Name'} = $tagsname if $tagsname;
    $filter{'name'}     = $name     if $name;
    %filter = (%filter, %$_) for (@filters);

    my @images = $ec2->describe_images(
        -owner  => $owner_id,
        -filter => \%filter,
    );
    return @images;
}

sub display_list {
    my ($images, $columns, $interactive) = @_;
    my @header = ($columns) ? @$columns : qw/tags_Name name imageId colorfulImageState/;

    my $print_format = '';
    $print_format .= "%-14s " for @header;

    my $no = 0;
    for (@$images) {
        my $cols = convert_row($_, \@header);
        if($interactive) {
            $print_format = '  %2d> ' . $print_format;
            printf ("$print_format\n" , ++$no, map { $_->{value} } @$cols);
        } else {
            printf ("$print_format\n" , map { $_->{value} } @$cols);
        }
    }
}

sub display_table {
    my ($images, $columns) = @_;
    my @data_header = ($columns) ? @$columns : qw/tags_Name name imageId colorfulImageState/;
    my @disp_header = ('no', @data_header);
    my $t = Text::ASCIITable->new();
    $t->setCols(@disp_header);

    my $no = 0;
    for (@$images) {
        my $cols = convert_row($_, \@data_header);
        $t->addRow([++$no, map { $_->{value} } @$cols]);
    }
    print $t;
}

sub convert_row {
    my ($image, $cols) = @_;

    my @results;
    for (@$cols) {
        push @results, {
            key   => $_,
            value => attribute_mapping($image, $_),
        };
    }
    return \@results;
}
sub attribute_mapping {
    my ($image, $key) = @_;

    my $value;
    if ($_ =~ /^tags_(.*)/) {
        $value = $image->tags->{$1};
    } elsif ($_ =~ /^blockDeviceMapping$/) {
        $value = $image->blockDeviceMapping;
    } elsif ($_ =~ /^colorfulImageState$/) {
        my $state = $image->imageState;
        $value = colored($state, _get_state_color($state));
    } else {
        $value = $image->{data}->{$_};
    }
    return $value || '';
}

sub _get_state_color {
    my ($status) = @_;
    if($status eq 'available') {
        return 'green';
    } elsif($status eq 'pending') {
        return 'yellow';
    } elsif($status eq 'failed') {
        return 'red';
    }
}

1;
