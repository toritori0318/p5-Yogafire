package Yogafire::Command::Plugin::amiwatcher;
use Mouse;
extends qw(Yogafire::CommandBase);
has 'timeout' => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "t",
    documentation => "Number of timeout second. (default : 480)",
);
has 'watch-status' => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "w",
    documentation => "specified image status (default : available)",
);
no Mouse;

use Yogafire::Image;
use Yogafire::Image::Action;
use Yogafire::Term;
use Yogafire::Declare qw/ec2 config/;

sub abstract {'EC2 image status watcher'}

sub execute {
    my ( $self, $opt, $args ) = @_;

    $opt->{'timeout'} ||= 480;
    $opt->{'watch-status'} ||= 'available';

    $opt->{owner} = 'self';

    my $y_image = Yogafire::Image->new();

    # tags name filter
    my $name = $args->[0];
    $opt->{name} = $name if $name;

    my @images = $y_image->search($opt);
    if(scalar @images == 0) {
        die "Not Found Instance. \n";
    } elsif(scalar @images == 1) {
        exit $self->watch($images[0], $opt->{'watch-status'}, $opt->{'timeout'});
    } else {
        die "Found more than one target. \n";
    }
}

sub watch {
    my ( $self, $image, $watch_status, $timeout ) = @_;

    my $counter = 0;
    my $max_count = $timeout / 5;
    while (1) {
        if($image->current_status eq $watch_status) {
            return 0;
        } elsif ($counter++ >= $max_count) {
            return -1;
        }
        sleep 5;
    }
}

1;
