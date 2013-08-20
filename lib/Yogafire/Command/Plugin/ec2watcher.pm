package Yogafire::Command::Plugin::ec2watcher;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

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
    documentation => "specified instance status (running / stopped  default:running)",
);
has tagsname => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "n",
    documentation   => "specified instance tagsname.",
);
no Mouse;

use Yogafire::Instance;

sub abstract {'EC2 instance status watcher'}

sub execute {
    my ( $self, $opt, $args ) = @_;

    $opt->{'timeout'} ||= 480;
    $opt->{'watch-status'} ||= 'running';

    my $y_ins = Yogafire::Instance->new();

    # tags name filter
    my $tagsname = $args->[0];
    $opt->{tagsname} = $tagsname if $tagsname;

    my @instances = $y_ins->search($opt);
    if(scalar @instances == 0) {
        return print "Not Found Instance. \n";
    } elsif(scalar @instances == 1) {
        exit $self->watch($instances[0], $opt->{'watch-status'}, $opt->{'timeout'});
    } else {
        return print "Found more than one target. \n";
    }
}

sub watch {
    my ( $self, $instance, $watch_status, $timeout ) = @_;

    my $counter = 0;
    my $max_count = $timeout / 5;
    while (1) {
        if($instance->current_status eq $watch_status) {
            return 0;
        } elsif ($counter++ >= $max_count) {
            return -1;
        }
        sleep 5;
    }
}

1;
