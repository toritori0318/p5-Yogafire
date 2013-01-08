package Yogafire::Instance::Action;
use strict;
use warnings;

use Yogafire::Instance::Action::SSH;
use Yogafire::Instance::Action::Start;
use Yogafire::Instance::Action::Stop;
use Yogafire::Instance::Action::Reboot;
use Yogafire::Instance::Action::Terminate;
use Yogafire::Instance::Action::CreateImage;
use Yogafire::Instance::Action::ChangeInstanceType;
use Yogafire::Instance::Action::Info;
use Yogafire::Instance::Action::Quit;
use Yogafire::Instance::Action::CopyAndLaunch;
use Yogafire::Instance::Action::UpdateTags;
use Yogafire::Instance::Action::ExtendVolume;

use Mouse;
extends 'Yogafire::ActionBase';

has 'actions' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        my $self = shift;
        return [
            Yogafire::Instance::Action::SSH->new(),
            Yogafire::Instance::Action::Start->new(),
            Yogafire::Instance::Action::Stop->new(),
            Yogafire::Instance::Action::Reboot->new(),
            Yogafire::Instance::Action::Terminate->new(),
            Yogafire::Instance::Action::CreateImage->new(),
            Yogafire::Instance::Action::ChangeInstanceType->new(),
            Yogafire::Instance::Action::CopyAndLaunch->new(),
            Yogafire::Instance::Action::UpdateTags->new(),
            Yogafire::Instance::Action::ExtendVolume->new(),
            Yogafire::Instance::Action::Info->new(),
            Yogafire::Instance::Action::Quit->new(),
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

sub action_print {
    my ($self, $instance) = @_;

    my $state = $instance->{data}->{instanceState}->{name} || '';
    my @commands = $self->get_commands($state);

    my $term = Yogafire::Term->new();

    print "\n";
    my $command = $term->get_reply(
        print_me => 'Instance Action.',
        prompt   => '  Input No > ',
        choices  => [map {$_->{name}} @commands],
    );
    $self->action($command)->run($instance);
}

sub get_commands {
    my ($self, $state) = @_;
    my @commands;

    my @actions  = @{$self->actions()};
    for my $action (@actions) {
        my $states = $action->{state} || ['.*'];
        if(grep { $state =~ /^$_/ } @$states) {
            push @commands, $action;
        }
    }
    return @commands;
}

1;
