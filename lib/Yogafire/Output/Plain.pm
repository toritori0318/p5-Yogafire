package Yogafire::Output::Plain;
use strict;
use warnings;
use Mouse;
has 'header' => (is => 'rw');
no Mouse;

sub output {
    my ($self, $rows) = @_;
    my $header = $self->header;

    my $print_format = '';
    $print_format .= "%-14s " for @$header;

    my $no = 0;
    for my $row (@$rows) {
        my $cols = $self->convert_row($row, $header);
        printf ("$print_format\n" , map { $_->{value} } @$cols);
    }
}

1;
