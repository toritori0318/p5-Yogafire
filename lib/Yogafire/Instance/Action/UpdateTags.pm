package Yogafire::Instance::Action::UpdateTags;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'update tags');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running pending shutting-down terminated stopping stopped/],
    },
);
no Mouse;

use Yogafire::Instance::Action::Info;
use Yogafire::Term;

sub run {
    my ($self, $instance) = @_;

    my $term = Yogafire::Term->new();
    my $key = $term->get_reply_required(
        prompt   => 'Tags keyname > ',
        default  => 'Name',
    );
    my $value = $term->get_reply_required(
        prompt   => 'Tags keyname > ',
        default  => $instance->tags->{$key}||'',
    );

    my $bool = $term->ask_yn(
        print_me => "\n[$key] = [$value]",
        prompt   => 'Update Ok ? ',
    );
    return unless $bool;

    $bool = $instance->add_tags($key => $value);
    if($bool) {
        print "Tags Updated. \n";
    } else {
        print "Tags Update Failuer. \n";
    }
};

1;
