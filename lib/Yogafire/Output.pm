package Yogafire::Output;
use strict;
use warnings;
use Mouse;
has 'header' => (is => 'rw');
has 'format' => (is => 'rw');
no Mouse;

use Yogafire::Output::Plain;
use Yogafire::Output::Table;

sub output {
    my ($self, $rows) = @_;
    my $format = $self->format || 'table';
    if($format eq 'table') {
        Yogafire::Output::Table->new({ header => $self->header })->output($rows);
    }
    elsif($format eq 'plain') {
        Yogafire::Output::Plain->new({ header => $self->header })->output($rows);
    }
}

1;
