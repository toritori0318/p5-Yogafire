package Yogafire::Image::Action;
use strict;
use warnings;

use Yogafire::Image::Action::RunInstance;
use Yogafire::Image::Action::Deregister;
use Yogafire::Image::Action::Info;

use Mouse;
extends 'Yogafire::ActionBase';

has 'actions' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        my $self = shift;
        return [
            Yogafire::Image::Action::RunInstance->new(),
            Yogafire::Image::Action::Deregister->new(),
            Yogafire::Image::Action::Info->new(),
        ];
    },
);

no Mouse;

use Yogafire::Term;

sub action {
    my ($self, $name) = @_;
    my $action_class = (grep { $_->name eq $name } @{$self->actions})[0];
    $action_class->ec2($self->ec2);
    $action_class->config($self->config);
    $action_class;
};

sub confirm {
    my ($self, $image) = @_;
    my $term = Yogafire::Term->new();

    my @commands = @{$self->actions()};

    print "\n";
    my $command = $term->get_reply(
        print_me => 'Image Action.',
        prompt   => '  Input No > ',
        choices  => [map {$_->{name}} @commands],
    );
    $self->action($command)->run($image);
}

1;
