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
        [qw/running pending shutting-down terminated stopping stopped/],
    },
);
no Mouse;

use Yogafire::Instance::Action::Info;
use Yogafire::Term;

sub run {
    my ($self, $instance, $opt) = @_;

    # show info
    Yogafire::Instance::Action::Info->new()->run($instance);

    my $input = $self->confirm_create_image($instance, $opt);
    return unless $input;

    print "Create image... \n";
    my $image_id = $instance->create_image(
        -name        => $input->{name},
        -description => $input->{description},
        -no_reboot   => $input->{reboot},
    );
    print " image id => [$image_id]\n";
    print "Create image in process. \n";
};

sub confirm_create_image {
    my ($self, $instance, $opt) = @_;
    $opt ||= {};
    my $name        = $opt->{name};
    my $description = $opt->{description};
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
        my $description = $term->get_reply(
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
