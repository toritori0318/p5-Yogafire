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
use File::Basename qw/fileparse/;
use File::Temp qw/tempdir/;
use File::Copy qw/move/;
use Cwd;
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
            if($opt->{hostprefix}) {
                $self->rsync_get_with_hostprefix($ssh, $host, $yoga_ssh->sync_option, $src, $dest);
            } else {
                $ssh->rsync_get($yoga_ssh->sync_option, $src, $dest) or die "rsync failed: " . $ssh->error;
            }
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

sub rsync_get_with_hostprefix {
    my ($self, $ssh, $host, $sync_option, $src, $dest) = @_;
    my ($dest_basename, $dest_dir) = fileparse $dest;

    my $tempdir = tempdir( CLEANUP => 1 );
    if(!$tempdir || $tempdir eq Cwd::getcwd()){
        die "hostprefix option is not supported.";
    }
    $tempdir .= "/";

    $ssh->rsync_get($sync_option, $src, $tempdir) or die "rsync failed: " . $ssh->error;

    my @tempfiles = glob "${tempdir}*";
    for my $file (@tempfiles) {
        my ($basename, $dir) = fileparse $file;
        my $to_basename = $dest_basename || $basename;
        my $tfile = sprintf("%s%s-%s", $dest_dir, $host, $to_basename);
        move($file, $tfile) or die "move failed: $!";
        print("[prefix file] >>> $tfile\n");
    }
}

1;
