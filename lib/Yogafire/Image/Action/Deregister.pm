package Yogafire::Image::Action::Deregister;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'deregister');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/available pending failed/],
    },
);
no Mouse;

use Yogafire::Logger;
use Yogafire::Image::Action::Info;
use Yogafire::Term;
use Yogafire::Declare qw/ec2 config/;

sub proc {
    my ($self, $image, $opt) = @_;

    my ($input) = $self->confirm($image, $opt);
    return unless $input;

    my $delete_snapshot = $input->{delete_snapshot};
    my $snapshot_id     = $input->{snapshot_id};

    yinfo(resource => $image, message => "<<<Start>>> Image Deregister.");
    unless(ec2->deregister_image($image->imageId)) {
        yerror(resource => $image, message => "<<<End>>> Image Deregister fail.");
    }

    if($delete_snapshot && $snapshot_id) {
        # wait for deregister...
        sleep 3;

        yinfo(resource => $image, message => " <Start> Snapshot delete.");
        unless(ec2->delete_snapshot($snapshot_id)) {
            yerror(resource => $image, message => "<<<End>>> Snapshot delete fail.");
        }
        yinfo(resource => $image, message => "  SnapshotID:$snapshot_id");
        yinfo(resource => $image, message => " <End> Snapshot delete.");
    }

    yinfo(resource => $image, message => "<<<End>>> Image Deregister.");
};

sub confirm {
    my ($self, $image, $opt) = @_;

    # show info
    Yogafire::Image::Action::Info->new()->procs($image);

    my $term = Yogafire::Term->new();
    my $delete_snapshot;
    my $snapshot_id;
    if($image->rootDeviceType eq 'ebs') {
        my @blockdevices = ();
        for my $blockdevice ($image->blockDeviceMapping) {
            push @blockdevices, $blockdevice;
            #    $print->('snapshotId', $blockdevice->ebs->snapshotId);
        }
        if(scalar @blockdevices == 1) {
            $snapshot_id = $blockdevices[0]->ebs->snapshotId;
        }
    }

    if($snapshot_id) {
        print "\n";
        $delete_snapshot = $term->ask_yn(
            prompt   => 'Do erase with the snapshot? > ',
            default  => 'n',
        );
    }

    print "\n";
    return unless $term->ask_yn(
        prompt   => 'Are you sure you want to deregister this image? > ',
    );

    return {
        snapshot_id     => $snapshot_id,
        delete_snapshot => $delete_snapshot,
    };
};

1;
