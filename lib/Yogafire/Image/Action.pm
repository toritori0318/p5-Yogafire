package Yogafire::Image::Action;
use strict;
use warnings;

use Yogafire::Image::Action::RunInstance;
use Yogafire::Image::Action::Deregister;
use Yogafire::Image::Action::Info;

use Mouse;
has 'action_name'  => (is => 'rw');
has 'action_class' => (is => 'rw');
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

sub BUILD {
    my ($self) = @_;
    my $action_name = $self->action_name;
    if($action_name) {
        my $action_class = $self->init_action($action_name);
        $self->action_class($action_class);
    }
}

sub init_action {
    my ($self, $name) = @_;
    my $action_class = (grep { $_->name eq $name } @{$self->actions})[0];
    $action_class;
};

sub run {
    my ($self, $target_image, $opt) = @_;

    if($self->action_class) {
        # run action
        $self->action_class->run($target_image, $opt);
    } else {
        # show action list
        $self->action_list($target_image, $opt);
    }
};

sub action_list {
    my ($self, $image, $opt) = @_;
    my $term = Yogafire::Term->new();

    my @commands = @{$self->actions()};

    print "\n";
    my $command = $term->get_reply(
        print_me => 'Image Action.',
        prompt   => '  Input No > ',
        choices  => [map {$_->{name}} @commands],
    );
    $self->init_action($command)->run($image, $opt);
}

1;
