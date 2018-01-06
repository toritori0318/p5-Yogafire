package Yogafire::Docker;
use strict;
use warnings;
use Mouse;
has 'out_columns' => (is => 'rw', default => sub { [
            'CONTAINER ID', 'IMAGE', 'COMMAND', 'CREATED', 'STATUS', 'NAMES'
        ] }, );
has 'out_format'  => (is => 'rw'), default => sub { "table" };
has 'cache'       => (is => 'rw');
no Mouse;

use Yogafire::Output;
use Term::ANSIColor qw/colored/;
use Yogafire::Declare qw/ec2 config/;

sub set_container_data_with_capture{
    my ($self, $capture) = @_;

    my @containers = split(/\n/, $capture);
    my $header = shift @containers;
    my @headers = split(/\|\|/, $header);

    my @data;
    for my $row (@containers) {
        push @data, [split(/\|\|/, $row)];
    }

    # set data
    $self->out_columns(\@headers);
    $self->cache(\@data);
}
sub find_from_cache {
    my ($self, $cond_regex) = @_;
    my @rows = $self->search_from_cache($cond_regex);
    return shift @rows;
}
sub search_from_cache {
    my ($self, $cond_regex) = @_;
    $cond_regex ||= "";

    my @search;
    for my $row (@{$self->cache}) {
        for my $col (@{$row}) {
            if($col =~ /$cond_regex/) {
                push @search, $row;
                last;
            }
        }
    }
    return @search;
}

sub output {
    my ($self) = @_;

    my $output = Yogafire::Output->new({ format => "table" });
    $output->header($self->out_columns);
    $output->output($self->cache);
}


1;
