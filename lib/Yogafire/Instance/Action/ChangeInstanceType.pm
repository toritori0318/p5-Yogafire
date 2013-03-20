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

use Yogafire::Instance::Action::Info;
use Yogafire::InstanceTypes;
use Yogafire::Term;
use Yogafire::Util qw/progress_dot/;

sub proc {
    my ($self, $instance, $opt) = @_;

    # show info
    Yogafire::Instance::Action::Info->new()->proc($instance);

    my $input = $self->confirm_create_image($instance, $opt);
    return unless $input;

    my $save_state = $instance->instanceState;
    # stop instance
    if($save_state ne 'stopped') {
        print "[Start] Stop Instance. \n";
        $instance->stop;
        progress_dot("Stop instance in process.", sub { $instance->current_state ne 'stopped' } );
        print "[End] Stop Instance. \n";
    }

    # change type
    print "[Start] Change Instance Type. \n";
    $instance->instanceType($input->{instance_type});
    print "[End] Change Instance Type. \n";

    # start instance
    if($save_state ne 'stopped') {
        print "[Start] Start Instance. \n";
        $instance->start;
        # wait running...
        progress_dot("Start instance in process.", sub { $instance->current_state ne 'running' } );
        # associate eip
        $instance->associate_address($input->{eip}) if !$instance->vpcId && $input->{eip};
        print "[End] Start Instance. \n";
    }

    print "[End] Change Instance Type. \n";
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

    my $find_eip = eval { $instance->ec2->describe_addresses(-public_ip => [$instance->ipAddress]) };
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
