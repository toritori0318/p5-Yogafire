package Yogafire::Instance::Action;
use strict;
use warnings;

use Yogafire::Instance::Action::SSH;
use Yogafire::Instance::Action::SSHTmux;
use Yogafire::Instance::Action::Start;
use Yogafire::Instance::Action::Stop;
use Yogafire::Instance::Action::Reboot;
use Yogafire::Instance::Action::Terminate;
use Yogafire::Instance::Action::CreateImage;
use Yogafire::Instance::Action::ChangeInstanceType;
use Yogafire::Instance::Action::Info;
use Yogafire::Instance::Action::Quit;
use Yogafire::Instance::Action::CopyAndLaunch;
use Yogafire::Instance::Action::ExtendVolume;

use Mouse;
has 'action_name'  => (is => 'rw');
has 'action_class' => (is => 'rw');
has 'actions'      => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        my $self = shift;
        return [
            Yogafire::Instance::Action::SSH->new(),
            Yogafire::Instance::Action::SSHTmux->new(),
            Yogafire::Instance::Action::Start->new(),
            Yogafire::Instance::Action::Stop->new(),
            Yogafire::Instance::Action::Reboot->new(),
            Yogafire::Instance::Action::Terminate->new(),
            Yogafire::Instance::Action::CreateImage->new(),
            Yogafire::Instance::Action::ChangeInstanceType->new(),
            Yogafire::Instance::Action::CopyAndLaunch->new(),
            Yogafire::Instance::Action::ExtendVolume->new(),
            Yogafire::Instance::Action::Info->new(),
            Yogafire::Instance::Action::Quit->new(),
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

sub state {
    my ($self) = @_;
    return ($self->action_class) ? $self->action_class->state : undef ;
}

sub procs {
    my ($self, $target_instances, $opt) = @_;

    if($self->action_class) {
        # run action
        $self->action_class->procs($target_instances, $opt);
    } else {
        # show action list
        $self->action_list($target_instances, $opt);
    }
};

sub action_list {
    my ($self, $instance, $opt) = @_;

    my $state = $instance->{data}->{instanceState}->{name} || '';
    my @commands = $self->get_commands($state);

    my $term = Yogafire::Term->new();

    print "\n";
    my $command = $term->get_reply(
        print_me => 'Instance Action.',
        prompt   => '  Input No > ',
        choices  => [map {$_->{name}} @commands],
    );
    $self->init_action($command)->proc($instance, $opt);
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
