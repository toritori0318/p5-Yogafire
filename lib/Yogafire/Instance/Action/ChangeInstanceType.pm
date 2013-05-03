package Yogafire::Instance::Action::ChangeInstanceType;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'changeinstancetype');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running stopped/],
    },
);
no Mouse;

use Yogafire::Logger;
use Yogafire::Instance::Action::Info;
use Yogafire::InstanceTypes;
use Yogafire::Term;
use Yogafire::Util qw/progress_dot/;
use Yogafire::Declare qw/ec2 config/;

sub proc {
    my ($self, $instance, $opt) = @_;

    # show info
    Yogafire::Instance::Action::Info->new()->proc($instance);

    my $input = $self->confirm_create_image($instance, $opt);
    return unless $input;

    yinfo(resource => $instance, message => "<<<Start>>> Change Instance Type.");

    my $save_state = $instance->instanceState;
    # stop instance
    if($save_state ne 'stopped') {
        yinfo(resource => $instance, message => " <Start> Stop Instance.");
        $instance->stop;
        progress_dot("Stop instance in process.", sub { $instance->current_state ne 'stopped' } );
        yinfo(resource => $instance, message => " <End> Stop Instance.");
    }

    # change type
    yinfo(resource => $instance, message => " <Start> Change Instance Type.");
    $instance->instanceType($input->{instance_type});
    yinfo(resource => $instance, message => " <End> Change Instance Type.");

    # start instance
    if($save_state ne 'stopped') {
        yinfo(resource => $instance, message => " <Start> Start Instance.");
        $instance->start;
        # wait running...
        progress_dot("Start instance in process.", sub { $instance->current_state ne 'running' } );
        # associate eip
        $instance->associate_address($input->{eip}) if !$instance->vpcId && $input->{eip};
        yinfo(resource => $instance, message => " <End> Start Instance.");
    }

    yinfo(resource => $instance, message => "<<<End>>> Change Instance Type.");
};

sub confirm_create_image {
    my ($self, $instance, $opt) = @_;
    $opt ||= {};
    my $instance_type = $opt->{type};
    my $force         = $opt->{force};

    my $instance_name     = $instance->tags->{Name};
    my $instance_id       = $instance->instanceId;
    my $old_instance_type = $instance->instanceType;

    my $y_instance_types = Yogafire::InstanceTypes->new();
    my $instance_types = $y_instance_types->instance_types;

    my $term = Yogafire::Term->new();
    my $m_instance_type;
    unless($instance_type) {
        while(1) {
            print "\n";
            $instance_type = $term->get_reply(
                prompt   => "Change Instance Type [$old_instance_type] > ",
                choices  => [map {$_->{id}} @$instance_types],
            );
            if($old_instance_type eq $instance_type) {
                print " [warn] Old instance type and new instance type is equal.\n";
                next;
            }
            last;
        }
    }

    my $find_eip = eval { ec2->describe_addresses(-public_ip => [$instance->ipAddress]) };
    my $eip      = ($find_eip) ? $instance->ipAddress : '';

    unless($force) {
        print "\n";
        my $confirm_str =<<"EOF";
================================================================
Change Instance Type

               Name : $instance_name
        Instance Id : $instance_id
         Elastic IP : $eip
      Instance Type : $old_instance_type -> $instance_type
================================================================
EOF

        my $prompt = "Change Instance Type OK?";
        $prompt .= " ([important] Instance will stop once, and resume after.) " if $instance->instanceState ne 'stopped';
        my $bool = $term->ask_yn(
            print_me => $confirm_str,
            prompt   => $prompt,
        );
        exit unless $bool;
    }

    return {
        instance_type => $instance_type,
        eip           => $eip,
    };
}

1;
