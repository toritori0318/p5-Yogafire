package Yogafire::Instance::Action::CreateImage;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'createimage');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running pending shutting-down stopping stopped/],
    },
);
no Mouse;

use Yogafire::Logger;
use Yogafire::Instance::Action::Info;
use Yogafire::Term;
use POSIX qw(strftime);

sub proc {
    my ($self, $instance, $opt) = @_;

    # show info
    Yogafire::Instance::Action::Info->new()->proc($instance);

    my $input = $self->confirm_create_image($instance, $opt);
    return unless $input;

    yinfo(resource => $instance, message => "<<<Start>>> Create image");
    print "Create image... \n";
    my $image_id = $instance->create_image(
        -name        => $input->{name},
        -description => $input->{description},
        -no_reboot   => $input->{reboot},
    );
    yinfo(resource => $instance, message => " ImageID: $image_id");
    yinfo(resource => $instance, message => "<<<End>>> Create image in process");
};

sub confirm_create_image {
    my ($self, $instance, $opt) = @_;
    $opt ||= {};
    my $name = $opt->{name};
    my $description = $opt->{description};
    if($opt->{autoname}) {
        my $tags_name = $instance->tags->{Name};
        my $gen_name = sprintf("%s-%s", $tags_name, strftime("%Y%m%d%H%M%S", localtime()));
        $name = $gen_name;
        $description = $gen_name;
    }
    my $noreboot    = $opt->{noreboot};
    my $force       = $opt->{force};

    my $term = Yogafire::Term->new();
    unless($name) {
        print "\n";
        $name = $term->get_reply_required(
            prompt   => 'Image Name > ',
        );
    }

    unless($description) {
        print "\n";
        $description = $term->get_reply(
            prompt   => 'Image Description > ',
        );
    }

    unless($noreboot) {
        print "\n";
        $noreboot = $term->ask_yn(
            prompt   => 'Instance No Reboot? > ',
            default  => 'n',
        );
    }
    my $display_noreboot = ($noreboot) ? 'yes' : 'no';

    my $confirm_str =<<"EOF";
================================================================
Create Image Info

         Image Name : $name
  Image Description : $description
 Instance No Reboot : $display_noreboot
================================================================
EOF
    unless($force) {
        print "\n";
        my $bool = $term->ask_yn(
            print_me => $confirm_str,
            prompt   => 'Create Image OK? ',
        );
        exit unless $bool;
    }

    return {
        name        => $name,
        description => $description,
        noreboot    => ($noreboot) ? 1 : 0,
    };
}

1;
