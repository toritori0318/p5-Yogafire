package Yogafire::Vpc;
use strict;
use warnings;
use Mouse;
has 'out_columns' => (is => 'rw', default => sub { [qw/tags_Name vpcId cidrBlock dhcpOptionsId instanceTenancy colorfulVpcState/] }, );
has 'out_format'  => (is => 'rw');
has 'cache'       => (is => 'rw');
no Mouse;

use Yogafire::Output;
use Term::ANSIColor qw/colored/;
use Yogafire::Declare qw/ec2 config/;

sub find {
    my ($self, $opts) = @_;
    my @rows = $self->search($opts);
    return shift @rows;
}

sub search {
    my ($self, $opts) = @_;
    $opts ||= {};

    my $host         = $opts->{host} || $opts->{tagsname};
    my $customfilter = $opts->{filter} || '';
    my @filters = ();
    for (split /,/, $customfilter) {
        my ($key, $value) = split /=/, $_;
        push @filters, { $key => $value };
    }

    # filter
    my %filter = ();
    if($host) {
        my %host_filter = $self->get_filter_from_host($host);
        %filter = (%filter, %host_filter);
    }
    %filter = (%filter, %$_) for (@filters);

    my @vpcs = ec2->describe_vpcs(
      -filter => \%filter,
    );

    $self->cache(\@vpcs);

    return @vpcs;
}

sub output {
    my ($self, $columns) = @_;
    my $output = Yogafire::Output->new({ format => $self->out_format });
    $output->header($self->out_columns);

    my @data;
    for my $row (@{$self->cache}) {
        my $cols = $self->convert_row($row, $self->out_columns);
        push @data, [map { $_->{value} } @$cols];
    }
    $output->output(\@data);
}

sub convert_row {
    my ($self, $vpc, $cols) = @_;

    my @results;
    for (@$cols) {
        push @results, {
            key   => $_,
            value => $self->attribute_mapping($vpc, $_),
        };
    }
    return \@results;
}

sub attribute_mapping {
    my ($self, $vpc, $key) = @_;

    my $value;
    if ($_ =~ /^tags_(.*)/) {
        $value = $vpc->tags->{$1};
    } elsif ($_ =~ /^colorfulVpcState$/) {
        my $state = $vpc->{data}->{state};
        $value = colored($state, $self->_get_state_color($state));
    } else {
        $value = $vpc->{data}->{$_};
    }
    return $value || '';
}

sub _get_state_color {
    my ($self, $status) = @_;
    if($status eq 'available') {
        return 'green';
    } elsif($status =~ m/^(pending)$/) {
        return 'yellow';
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

    my $terms = {
        id => sub {
            my ($i, $cond) = @_;
            return unless $cond;
            my $id = $i->vpcId;
            return $id =~ /$cond/
        },
        name => sub {
            my ($i, $cond) = @_;
            return unless $cond;
            my $name = $i->tags->{Name} || '';
            return $name =~ /$cond/
        },
    };

    my @search;
    for my $key (keys %$cond) {
        my $cond_val = $cond->{$key}||'';
        next unless $cond_val;

        for my $vpc (@{$self->cache}) {
            if($terms->{$key}->($vpc, $cond_val)) {
                push @search, $vpc;
            }
        }
    }
    return @search;
}

1;
