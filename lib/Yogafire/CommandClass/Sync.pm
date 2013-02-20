package Yogafire::CommandClass::Sync;
use Mouse;
has mode => (
    isa => "Str",
    is  => "rw",
    required => "1",
);
has ec2 => ( is  => "rw" );
has config => ( is  => "rw" );
no Mouse;

use Net::OpenSSH;
use Yogafire::Instance qw/list/;
use Yogafire::CommandClass::SSH;

sub execute {
    my ( $self, $opt, $args, $is_default_option ) = @_;
    my $ec2  = $self->ec2;
    my $config = $self->config;

    my $host = shift @$args;
    my $src  = shift @$args;
    my $dest = shift @$args;

    my $condition = {};
    if ($host =~ /^(\d+).(\d+).(\d+).(\d+)$/) {
        $condition->{filter} = ($1 == 10) ? "private-ip-address=$host" : "ip-address=$host";
    } else {
        $condition->{tagsname} = $host;
    }
    $condition->{state} = 'running';

    my @instances = list($ec2, $condition);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    # rsync loop
    for (@instances) {
        my $yoga_ssh = Yogafire::CommandClass::SSH->new(
            {
                ec2    => $ec2,
                config => $config,
                opt    => $opt,
            }
        );
        my $name = $_->tags->{Name} || '';
        my $host = $yoga_ssh->target_host($_);
        printf "# Sync %s %s@%s(%s)\n", $self->mode, $self->config->get('ssh_user'), $host, $name;

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
    }
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
