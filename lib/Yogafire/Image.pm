package Yogafire::Image;
use strict;
use warnings;
use Mouse;
has 'out_columns' => (is => 'rw', default => sub { [qw/tags_Name name imageId colorfulImageState/] }, );
has 'out_format'  => (is => 'rw');
has 'cache'      => (is => 'rw');
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

    my $owner        = $opts->{owner};
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

    my %image_filter = ('-filter' => \%filter);
    $image_filter{'-owner'} = $owner if $owner;

    my @images = ec2->describe_images(%image_filter);
    $self->cache(\@images);

    return @images;
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
    my ($self, $image, $cols) = @_;

    my @results;
    for (@$cols) {
        push @results, {
            key   => $_,
            value => $self->attribute_mapping($image, $_),
        };
    }
    return \@results;
}

sub attribute_mapping {
    my ($self, $image, $key) = @_;

    my $value;
    if ($_ =~ /^tags_(.*)/) {
        $value = $image->tags->{$1};
    } elsif ($_ =~ /^blockDeviceMapping$/) {
        $value = $image->blockDeviceMapping;
    } elsif ($_ =~ /^colorfulImageState$/) {
        my $state = $image->imageState;
        $value = colored($state, $self->_get_state_color($state));
    } else {
        $value = $image->{data}->{$_};
    }
    return $value || '';
}

sub _get_state_color {
    my ($self, $status) = @_;
    if($status eq 'available') {
        return 'green';
    } elsif($status eq 'pending') {
        return 'yellow';
    } elsif($status eq 'failed') {
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
            my $id = $i->imageId;
            return $id =~ /$cond/
        },
        name => sub {
            my ($i, $cond) = @_;
            return unless $cond;
            my $name = $i->name || '';
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

1;
