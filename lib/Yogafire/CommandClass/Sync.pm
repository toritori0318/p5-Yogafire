package Yogafire::CommandClass::Sync;
use Mouse;
has mode => (
    isa => "Str",
    is  => "rw",
    required => "1",
);
no Mouse;

use Net::OpenSSH;
use Parallel::ForkManager;
use Yogafire::Logger;
use Yogafire::Instance;
use Yogafire::CommandClass::SSH;
use Yogafire::Declare qw/ec2 config/;

sub execute {
    my ( $self, $opt, $args, $is_default_option ) = @_;

    my $y_ins = Yogafire::Instance->new();

    my $host = shift @$args;
    my $src  = shift @$args;
    my $dest = shift @$args;

    my $condition = {};
    $condition->{host}  = $host;
    $condition->{state} = 'running';

    my @instances = $y_ins->search($condition);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    my $concurrency = $opt->{concurrency} || 1;
    my $pm = Parallel::ForkManager->new($concurrency);

    # rsync loop
    for my $instance (@instances) {
        my $pid = $pm->start and next;

        my $yoga_ssh = Yogafire::CommandClass::SSH->new(
            {
                opt    => $opt,
            }
        );
        my $name = $instance->tags->{Name} || '';
        my $host = $yoga_ssh->target_host($instance);
        yinfo(resource => $instance, message => sprintf("Sync %s", $self->mode));

        # set default
        $self->set_default_option($yoga_ssh->sync_option) if $is_default_option;
        # exec ssh
        my $ssh = $yoga_ssh->ssh(
            {
                host => $host,
            }
        );

        if($self->mode eq 'put') {
            $ssh->rsync_put($yoga_ssh->sync_option, $src, $dest) or die "rsync failed: " . $ssh->error;
        } else {
            $ssh->rsync_get($yoga_ssh->sync_option, $src, $dest) or die "rsync failed: " . $ssh->error;
        }
        $pm->finish;
    }

    $pm->wait_all_children;
}

sub set_default_option {
    my ($self, $opt) = @_;
    for my $option (qw/recursive glob verbose update archive compress/) {
        unless($opt->{$option}) {
            $opt->{$option} = 1;
        }
    }
}

1;
