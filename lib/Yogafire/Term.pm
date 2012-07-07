package Yogafire::Term;
use strict;
use warnings;

use parent "Term::ReadLine";
use Term::UI;

sub get_reply_required {
    my $self = shift;
    my (%opt) = @_;
    while(1) {
        my $value = $self->get_reply(%opt);
        if($value) {
            return $value;
        } else {
            print "This value is required.\n";
        }
    }
}

1;
