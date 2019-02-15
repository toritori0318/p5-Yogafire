package Yogafire::Term;
use strict;
use warnings;

use parent "Term::ReadLine";
use Term::UI;

sub new {
    my $class = shift;
    $_[0] = "yogash" if scalar(@_) == 0;
    my $self = $class->SUPER::new(@_);

    my $attribs = $self->Attribs;
    $attribs->{completion_entry_function} = $attribs->{list_completion_function};

    $self;
}

sub set_completion_word {
    my ($self, $words) = @_;
    my $attribs = $self->Attribs;
    $attribs->{completion_word} = $words;
}

sub mask_password {
    my ($self, $words) = @_;
    my $attribs = $self->Attribs;
    $attribs->{redisplay_function} = $attribs->{shadow_redisplay};
    return $self->readline("password> ");
}

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
