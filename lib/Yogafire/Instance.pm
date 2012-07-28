package Yogafire::Instance;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw/list display_list display_table attribute_mapping/;

use Text::ASCIITable;
use Term::ANSIColor qw/colored/;

sub list {
    my ($ec2, $opts) = @_;
    $opts ||= {};

    my $state        = $opts->{state};
    my $tagsname     = $opts->{tagsname};
    my $customfilter = $opts->{filter} || '';
    my @filters = ();
    for (split /,/, $customfilter) {
        my ($key, $value) = split /=/, $_;
        push @filters, { $key => $value };
    }

    # filter
    my %filter = ();
    $filter{'instance-state-name'} = $state    if $state;
    $filter{'tag:Name'}            = $tagsname if $tagsname;
    %filter = (%filter, %$_) for (@filters);

    my @instances = $ec2->describe_instances(
      -filter => \%filter,
    );
    return @instances;
}

sub display_list {
    my ($instances, $columns, $interactive) = @_;
    my @header = ($columns) ? @$columns : qw/tags_Name instanceId ipAddress privateIpAddress dnsName colorfulInstanceState/;

    my $print_format = '';
    $print_format .= "%-14s " for @header;

    my $no = 0;
    for (@$instances) {
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
    my ($instances, $columns) = @_;
    my @data_header = ($columns) ? @$columns : qw/tags_Name instanceId ipAddress privateIpAddress dnsName colorfulInstanceState/;
    my @disp_header = ('no', @data_header);
    my $t = Text::ASCIITable->new();
    $t->setCols(@disp_header);

    my $no = 0;
    for (@$instances) {
        my $cols = convert_row($_, \@data_header);
        $t->addRow([++$no, map { $_->{value} } @$cols]);
    }
    print $t;
}

sub convert_row {
    my ($instance, $cols) = @_;

    my @results;
    for (@$cols) {
        push @results, {
            key   => $_,
            value => attribute_mapping($instance, $_),
        };
    }
    return \@results;
}

sub attribute_mapping {
    my ($instance, $key) = @_;

    my $value;
    if ($_ =~ /^tags_(.*)/) {
        $value = $instance->tags->{$1};
    } elsif ($_ =~ /^groupSet$/) {
        $value = join(',', (map {$_->groupName} $instance->groups) );
    } elsif ($_ =~ /^instanceState$/) {
        $value = $instance->{data}->{instanceState}->{name};
    } elsif ($_ =~ /^monitoring$/) {
        $value = $instance->monitoring;
    } elsif ($_ =~ /^availabilityZone$/) {
        $value = $instance->placement;
    } elsif ($_ =~ /^colorfulInstanceState$/) {
        my $state = $instance->{data}->{instanceState}->{name};
        $value = colored($state, _get_state_color($state));
    } else {
        $value = $instance->{data}->{$_};
    }
    return $value || '';
}

sub _get_state_color {
    my ($status) = @_;
    if($status eq 'running') {
        return 'green';
    } elsif($status =~ m/^(pending|shutting-down|stopping)$/) {
        return 'yellow';
    } elsif($status =~ m/^(terminated|stopped)$/) {
        return 'red';
    }
}

1;
