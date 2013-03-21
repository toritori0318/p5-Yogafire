package Yogafire::Instance::Action::SSH;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'ssh');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running/],
    },
);
no Mouse;

use Yogafire::Instance qw/list/;
use Yogafire::CommandClass::SSH;

sub proc {
    my ($self, $instance, $opt) = @_;

    my $yoga_ssh = Yogafire::CommandClass::SSH->new(
        {
            opt    => $opt,
        }
    );
    my $ssh_cmd = $yoga_ssh->build_raw_ssh_command($instance);
    print "$ssh_cmd\n";
    exec($ssh_cmd);
};

1;

