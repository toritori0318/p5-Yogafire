package Yogafire::Instance;
use strict;
use warnings;
use Mouse;
has 'ec2'         => (is => 'rw', isa => 'VM::EC2');
has 'out_columns' => (is => 'rw', default => sub { [qw/tags_Name instanceId ipAddress privateIpAddress dnsName colorfulInstanceState/] }, );
has 'out_format'  => (is => 'rw');
has 'instances'   => (is => 'rw');
no Mouse;

use Yogafire::Output;
use Text::ASCIITable;
use Term::ANSIColor qw/colored/;

sub find {
    my ($self, $opts) = @_;
    my @rows = $self->search($opts);
    return shift @rows;
}

sub search {
    my ($self, $opts) = @_;
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

    my @instances = $self->ec2->describe_instances(
      -filter => \%filter,
    );

    $self->instances(\@instances);

    return @instances;
}

sub output {
    my ($self, $columns) = @_;
    my $output = Yogafire::Output->new({ format => $self->out_format });
    $output->header($self->out_columns);

    my @data;
    for my $row (@{$self->instances}) {
        my $cols = $self->convert_row($row, $self->out_columns);
        push @data, [map { $_->{value} } @$cols];
    }
    $output->output(\@data);
}

sub convert_row {
    my ($self, $instance, $cols) = @_;

    my @results;
    for (@$cols) {
        push @results, {
            key   => $_,
            value => $self->attribute_mapping($instance, $_),
        };
    }
    return \@results;
}

sub attribute_mapping {
    my ($self, $instance, $key) = @_;

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
        $value = colored($state, $self->_get_state_color($state));
    } else {
        $value = $instance->{data}->{$_};
    }
    return $value || '';
}

sub _get_state_color {
    my ($self, $status) = @_;
    if($status eq 'running') {
        return 'green';
    } elsif($status =~ m/^(pending|shutting-down|stopping)$/) {
        return 'yellow';
    } elsif($status =~ m/^(terminated|stopped)$/) {
        return 'red';
    }
}

sub find_from_cache {
    my ($self, $cond) = @_;
    my @rows = $self->search_from_cache($cond);
    return shift @rows;
}
sub search_from_cache {
    my ($self, $cond ) = @_;
    $cond ||= {};

    my @search;
    for my $key (qw/id name/) {
        my $cond_val = quotemeta($cond->{$key}||'');
        next unless $cond_val;

        for my $instance (@{$self->instances}) {
            if(($key eq 'id'   && $instance->instanceId   eq $cond_val) ||
               ($key eq 'name' && $instance->tags->{Name} eq $cond_val)
            ) {
                push @search, $instance;
            }
        }
    }
    return @search;
}

sub ng_name {
    my ($self, $instances) = @_;
    my @names = grep { $_ if $_ } map { $_->tags->{Name} } @$instances;
    my %sum_name;
    $sum_name{$_}++ for @names;
    return grep { $sum_name{$_} > 1 } keys %sum_name;
}

1;
