package Yogafire::Util;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw/progress_dot/;

sub progress_dot {
    my ($header, $sub) = @_;
    $| = 1;

    print $header;

    while ($sub->()) {
        print ".";
        sleep 3;
    }

    print "\n";
}

1;
