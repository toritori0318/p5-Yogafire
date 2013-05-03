package Yogafire::Instance::Action::ExtendVolume;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'expandvolume');
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
use Yogafire::Term;
use Yogafire::Util qw/progress_dot/;
use Yogafire::Declare qw/ec2 config/;

sub proc {
    my ($self, $instance, $opt) = @_;

    # show info
    Yogafire::Instance::Action::Info->new()->proc($instance);

    my $input = $self->confirm_create_image($instance, $opt);
    return unless $input;

    yinfo(resource => $instance, message => "<<<Start>>> Extend Volume.");

    my $save_state = $instance->instanceState;
    # stop instance
    if($save_state ne 'stopped') {
        yinfo(resource => $instance, message => " <Start> Stop Instance.");
        $instance->stop;
        progress_dot("Stop instance in process.", sub { $instance->current_state ne 'stopped' } );
        yinfo(resource => $instance, message => " <End> Stop Instance.");
    }

    my $cur_volume = $input->{volume};
    my $snapshot;
    my $new_volume;
    {
        yinfo(resource => $instance, message => " <Start> Create new snapshot from this volume.");
        $snapshot = $cur_volume->create_snapshot("Yoga Extend Snapshot at ".localtime);
        progress_dot("Snapshot create in process.", sub { $snapshot->current_status ne 'completed' } );
        my $message = sprintf "Snapshot status: %s %s", $snapshot->snapshotId, $snapshot->current_status;
        yinfo(resource => $instance, message => $message);
        yinfo(resource => $instance, message => " <End> Create new snapshot from this volume.");
    }

    {
        yinfo(resource => $instance, message => " <Start> Create new volume.");
        my %args = (
            -size              => $input->{update_size},
            -availability_zone => $input->{availability_zone},
        );
        $new_volume = $snapshot->create_volume(%args);
        progress_dot("Create new volume in process.", sub { $new_volume->current_status ne 'available' } );
        my $message = sprintf "New volume status: %s %s", $new_volume->volumeId, $new_volume->current_status;
        yinfo(resource => $instance, message => $message);
        yinfo(resource => $instance, message => " <End> Create new volume.");
    }

    my $device_name = $input->{device_name};
    eval {
        {
            yinfo(resource => $instance, message => " <Start> Detach current volume.");
            my $attachment = $cur_volume->detach();
            progress_dot("Detach current volume in process.", sub { $attachment->current_status ne 'detached' } );
            yinfo(resource => $instance, message => " <End> Detach current volume.");
        }

        {
            yinfo(resource => $instance, message => " <Start> Attach instance volume from new volume.");
            my %args = (
                -instance_id => $instance->instanceId,
                -device      => $device_name,
            );
            my $attachment = $new_volume->attach(%args);
            progress_dot("Attach volume in process.", sub { $attachment->current_status ne 'attached' } );
            my $message = sprintf "attachment status: %s", $attachment->current_status;
            yinfo(resource => $instance, message => $message);
            yinfo(resource => $instance, message => " <End> Attach instance volume from new volume.");
        }
    };
    if($@) {
        ycrit(resource => $instance, message => " <Exception> $@");
        yinfo(resource => $instance, message => " <Start> Rollback...");
        my %args = (
            -instance_id => $instance->instanceId,
            -device      => $device_name,
        );
        my $attachment = $cur_volume->attach(%args);
        progress_dot("Rollback volume in process.", sub { $attachment->current_status ne 'attached' } );
        yinfo(resource => $instance, message => " <End> Rollback...");
        return;
    }

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

    yinfo(resource => $instance, message => "<<<End>>> Extend Volume.");

    my $complete_str =<<"EOF";

Please execute the following commands. (After loggin as root)

# resize fs
resize2fs $device_name

# confirm
df -h

EOF
    print $complete_str;

};

sub confirm_create_image {
    my ($self, $instance, $opt) = @_;
    $opt ||= {};

    my $update_size       = $opt->{size};
    my $availability_zone = $opt->{availability_zone} || $instance->placement;

    # 現在のボリューム情報取得
    my $instance_name   = $instance->tags->{Name};
    my $instance_id     = $instance->instanceId;
    my @devices         = $instance->blockDeviceMapping;
    my $device          = shift @devices;
    my $cur_device_name = $device->deviceName;
    my $cur_volume_id   = $device->volume->volumeId;
    my $cur_size        = $device->volume->size;

    my $force = $opt->{force};

    my $term = Yogafire::Term->new();
    unless($update_size) {
        while(1) {
            print "\n";
            $update_size = $term->get_reply(
                prompt   => "Update Volume Size [$cur_size]> ",
                allow    => qr/\d+/,
            );

            #size validation
            if($cur_size >= $update_size) {
                print "[warn] size is invalid. (cur_size >= update_size).\n";
                next;
            }
            last;
        }
    }

    my $find_eip = eval { ec2->describe_addresses(-public_ip => [$instance->ipAddress]) };
    my $eip      = ($find_eip) ? $instance->ipAddress : '';

    my $confirm_str =<<"EOF";
================================================================
Expand Volume

               Name : $instance_name
        Instance Id : $instance_id
         Elastic IP : $eip
        device_name : $cur_device_name
          volume_id : $cur_volume_id
  availability zone : $availability_zone
               size : ${cur_size}\[GB\] -> ${update_size}\[GB\]

================================================================
EOF

    unless($force) {
        print "\n";
        my $prompt = "Expand Volume OK?";
        $prompt .= " ([important] Instance will stop once, and resume after.) " if $instance->instanceState ne 'stopped';
        my $bool = $term->ask_yn(
            print_me => $confirm_str,
            prompt   => $prompt,
        );
        exit unless $bool;
    }

    return {
        device            => $device,
        volume            => $device->volume,
        device_name       => $cur_device_name,
        volume_id         => $cur_volume_id,
        size              => $cur_size,
        update_size       => $update_size,
        availability_zone => $availability_zone,
        eip               => $eip,
    };
}

1;
