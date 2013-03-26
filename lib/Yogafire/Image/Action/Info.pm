package Yogafire::Image::Action::Info;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'info');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/available pending failed/],
    },
);
no Mouse;

sub proc {
    my ($self, $image) = @_;
    my $print = sub {
        printf "  %16s: %s\n", $_[0], $_[1]||'';
    };
    printf("%s Image Info %s\n", '='x16, '='x16);
    $print->('Tag:Name', $image->tags->{Name});
    $print->('Name', $image->name);
    $print->('current_status', $image->imageState);
    for my $key ( qw/imageId imageOwnerId description isPublic/) {
        $print->($key, $image->{data}->{$key});
    }
    $print->('rootDeviceType', $image->rootDeviceType);
    $print->('blockDeviceMapping', $image->blockDeviceMapping);
    if($image->rootDeviceType eq 'ebs') {
        for my $blockdevice ($image->blockDeviceMapping) {
            $print->('snapshotId', $blockdevice->ebs->snapshotId);
        }
    }
};

1;
