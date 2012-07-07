package Yogafire::Command;
use strict;
use warnings;
use Mouse;
extends qw(MouseX::App::Cmd::Command);

has 'verbose'=> (
    traits => [qw(Getopt)],
    isa => "Bool",
    is  => "rw",
    cmd_aliases => 'v',
    documentation => "Show command verbose.",
);

no Mouse;

use Yogafire::Instance qw/list display_list display_table/;
use Yogafire::Instance::Action;
use Yogafire::Term;

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->validate_args_common($opt, $args );
};

sub validate_args_common {
    my ($self, $opt, $args) = @_;

    # help
    die $self->usage if $opt->{help_flag};

    # illegal option
    for (@$args) {
        $self->usage_error("$_: illegal option.") if $_ =~ /^-/;
    }

    #
    if(ref $self ne 'Yogafire::Command::config' && !-e $self->config->file) {
        die sprintf("Can't find config file [%s]\nPlease excecute \"yoga config --init\"\n", $self->config->file);
    }
};

sub action_process {
    my ($self, $action_name, $opt ) = @_;
    $opt ||= {};

    my $ia = Yogafire::Instance::Action->new(ec2 => $self->ec2, config => $self->config);
    my $ia_action = $ia->action($action_name);
    my $state = $ia_action->state;

    $opt->{state} = $state;

    my @instances = list($self->ec2, $opt);
    if(scalar @instances == 0) {
        print "Not Found Instance. \n";
        return;
    } elsif(scalar @instances == 1) {
        $ia_action->run($instances[0]);
        return;
    }

    my $column_list = $self->config->get('instance_column');
    display_table(\@instances, $column_list, 1);

    my $term = Yogafire::Term->new('Input Number');
    while (1) {
        my $input = $term->readline('Input No > ');
        last if $input =~ /^(q|quit|exit)$/;

        if ($input !~ /^\d+$/ || !$instances[$input-1]) {
            print "Invalid Number. \n";
            next;
        }
        $ia_action->run($instances[$input-1], $opt);
        last;
    }
}

1;
