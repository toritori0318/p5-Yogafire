package Yogafire::Image;
use strict;
use warnings;
use Mouse;
has 'ec2'         => (is => 'rw', isa => 'VM::EC2');
has 'out_columns' => (is => 'rw', default => sub { [qw/tags_Name name imageId colorfulImageState/] }, );
has 'out_format'  => (is => 'rw');
has 'images'      => (is => 'rw');
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

    my @images = $self->ec2->describe_images(
        -owner  => $owner_id,
        -filter => \%filter,
    );

    $self->images(\@images);

    return @images;
}

sub output {
    my ($self, $columns) = @_;
    my $output = Yogafire::Output->new({ format => $self->out_format });
    $output->header($self->out_columns);

    my @data;
    for my $row (@{$self->images}) {
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

    my @search;
    for my $key (qw/id name/) {
        my $cond_val = quotemeta($cond->{$key}||'');
        next unless $cond_val;

        for my $image (@{$self->images}) {
            if(($key eq 'id'   && $image->imageId eq $cond_val) ||
               ($key eq 'name' && $image->name    eq $cond_val)
            ) {
                push @search, $image;
            }
        }
    }
    return @search;
}

1;
