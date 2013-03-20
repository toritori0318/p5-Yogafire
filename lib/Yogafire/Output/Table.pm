package Yogafire::Output::Table;
use strict;
use warnings;
use Mouse;
has 'header' => (is => 'rw');
no Mouse;

use Text::UnicodeTable::Simple;
use Term::ANSIColor qw/colored/;

sub output {
    my ($self, $rows) = @_;
    my $data_header = $self->header;
    my @disp_header = ('no', @$data_header);
    my $t = Text::UnicodeTable::Simple->new(
        header     => \@disp_header,
        ansi_color => 1,
    );

    my $no = 0;
    for my $row (@$rows) {
        $t->addRow([++$no, @$row]);
    }
    print $t;
}

1;
