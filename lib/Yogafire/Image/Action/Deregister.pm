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

use Yogafire::Image::Action::Info;
use Yogafire::Term;
use Yogafire::Declare qw/ec2 config/;

sub run {
    my ($self, $image) = @_;

    # show info
    Yogafire::Image::Action::Info->new()->run($image);

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

    print "Image Deregister... \n";
    if(ec2->deregister_image($image->imageId)) {
        print "Image Deregister process. \n";
    } else {
        print "Image Deregister fail. \n";
    }

    if($delete_snapshot && $snapshot_id) {
        # wait for deregister...
        sleep 3;

        print "Snapshot delete... \n";
        if(ec2->delete_snapshot($snapshot_id)) {
            print "Snapshot delete process. \n";
        } else {
            print "Snapshot delete fail. \n";
        }
    }
};

1;
