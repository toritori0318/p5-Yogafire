package Yogafire::Instance;
use strict;
use warnings;
use Mouse;
has 'out_columns' => (is => 'rw', default => sub { [qw/tags_Name instanceId ipAddress privateIpAddress dnsName colorfulInstanceState/] }, );
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

    my @instance_ids = ($opts->{instance_ids}) ? @{$opts->{instance_ids}}: ();
    my $state        = $opts->{state};
    my $host         = $opts->{host} || $opts->{tagsname};
    my $customfilter = $opts->{filter} || '';
    my @filters = ();
    for (split /,/, $customfilter) {
        my ($key, $value) = split /=/, $_;
        push @filters, { $key => $value };
    }

    # filter
    my %filter = ();
    $filter{'instance-state-name'} = $state if $state;
    if($host) {
        my %host_filter = $self->get_filter_from_host($host);
        %filter = (%filter, %host_filter);
    }
    %filter = (%filter, %$_) for (@filters);

    my %args = (-filter => \%filter);
    $args{'-instance_id'} = \@instance_ids if scalar @instance_ids > 0;
    # get instances
    my @instances = ec2->describe_instances(%args);
    # set cache
    $self->cache(\@instances);

    return @instances;
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

    my $terms = {
        id => sub {
            my ($i, $cond) = @_;
            return unless $cond;
            my $id = $i->instanceId;
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

        for my $instance (@{$self->cache}) {
            if($terms->{$key}->($instance, $cond_val)) {
                push @search, $instance;
            }
        }
    }
    return @search;
}

sub get_filter_from_host {
    my ($self, $host) = @_;

    my %filter = ();
    if ($host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
        # ip address
        if($1 == 10) {
            $filter{'private-ip-address'} = $host;
        } else {
            $filter{'ip-address'} = $host;
        }
    } elsif ($host =~ /^ip-(\d+)-(\d+)-(\d+)-(\d+)/) {
        # private dns name
        $filter{'private-dns-name'} = $host;
    } elsif ($host =~ /^ec2-(\d+)-(\d+)-(\d+)-(\d+)/) {
        # public dns name
        $filter{'dns-name'} = $host;
    } elsif($host =~ m/^i-[0-9a-zA-Z]{8}$/) {
        # instance id
        $filter{'instance-id'} = $host;
    } else {
        # tag name
        $filter{'tag:Name'} = $host;
    }

    return %filter;
}

1;
