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
        [qw/stopping stopped/],
    },
);
no Mouse;

use Yogafire::Instance::Action::Info;
use Yogafire::Term;

sub run {
    my ($self, $instance, $opt) = @_;

    # show info
    Yogafire::Instance::Action::Info->new()->run($instance);

    $DB::single = 1;

    my $input = $self->confirm_create_image($instance, $opt);
    return unless $input;

    my $cur_volume = $input->{volume};

    my $snapshot;
    my $new_volume;
    {
        print "[Start] Create new snapshot from this volume. \n";
        $snapshot = $cur_volume->create_snapshot("Yoga Extend Snapshot at ".localtime);
        print "Snapshot create in process... \n";
        while ($snapshot->current_status eq 'pending') {
            sleep 5;
        }
        printf "Snapshot status: [%s] [%s] \n", $snapshot->snapshotId, $snapshot->current_status;
        print "[End] Create new snapshot from this volume. \n";
    }

    {
        print "[Start] Create new volume. \n";
        my %args = (
            -size              => $input->{update_size},
            -availability_zone => $input->{availability_zone},
        );
        $new_volume = $snapshot->create_volume(%args);
        while ($new_volume->current_status eq 'pending') {
            sleep 5;
        }
        printf "New volume status: [%s] [%s] \n", $new_volume->volumeId, $new_volume->current_status;
        print "[End] Create new volume. \n";
    }

    eval {
        {
            print "[Start] Detach current volume... \n";
            my $attachment = $cur_volume->detach();
            while ($attachment->current_status ne 'detached') {
                sleep 5;
            }
            print "[End] Detach current volume... \n";
        }

        {
            print "[Start] Attach instance volume from new volume... \n";
            my %args = (
                -instance_id => $instance->instanceId,
                -device      => $input->{device_name},
            );
            my $attachment = $new_volume->attach(%args);
            while ($attachment->current_status ne 'attached') {
                sleep 5;
            }
            print "attachment status: ",$attachment->current_status,"\n";
            print "[End] Attach instance volume from new volume... \n";
        }
    };
    if($@) {
        warn $@;
        print "[Start] Rollback... \n";
        my %args = (
            -instance_id => $instance->instanceId,
            -device      => $input->{device_name},
        );
        my $attachment = $cur_volume->attach(%args);
        while ($attachment->current_status ne 'attached') {
            sleep 5;
        }
        print "[End] Rollback... \n";
    }

    print "Extend Volume completed. \n";
    my $complete_str =<<"EOF";

Please execute the following commands. (After loggin as root)

# resize fs
resize2fs /dev/sda1

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
    my @devices   = $instance->blockDeviceMapping;
    my $device    = shift @devices;
    my $cur_device_name = $device->deviceName;
    my $cur_volume_id   = $device->volume->volumeId;
    my $cur_size        = $device->volume->size;

    my $force = $opt->{force};

    my $term = Yogafire::Term->new();

    my $confirm_str =<<"EOF";
================================================================
Expand Volume

        device_name : $cur_device_name
          volume_id : $cur_volume_id
  availability zone : $availability_zone
               size : ${cur_size}\[GB\] -> ${update_size}\[GB\]

================================================================
EOF


    #size validation
    if($cur_size >= $update_size) {
        die "--size is invalid. [cur_size >= update_size].";
    }


    unless($force) {
        print "\n";
        my $bool = $term->ask_yn(
            print_me => $confirm_str,
            prompt   => 'Expand Volume OK? ',
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
    };
}

1;
