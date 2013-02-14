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

sub execute {
    my ( $self, $opt, $args, $default_option ) = @_;
    my $ec2  = $self->ec2;
    my $config = $self->config;

    my $tagsname = shift @$args;
    my $src      = shift @$args;
    my $dest     = shift @$args;

    my @instances = list($ec2, { tagsname => $tagsname, state => 'running' });
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    # parse option
    my $parse_option = $self->parse_option($opt->{sync_option}, $default_option);
    $parse_option->{'dry-run'} = 1 if $opt->{'dry-run'};

    for (@instances) {
        my $name = $_->tags->{Name} || '';
        printf "# Sync %s@%s(%s)\n", $self->config->get('ssh_user'), $_->ip_address, $name;
        my $results = $self->exec_ssh(
            $config->get('identity_file'),
            $config->get('ssh_user'),
            $_->dns_name,
            $src,
            $dest,
            $parse_option,
        );
    }
}

sub parse_option {
    my ($self, $sync_option, $default_option) = @_;
    my $cnv_option = {};
    # default option
    if($default_option) {
        $cnv_option->{verbose}   = 1;
        $cnv_option->{update}    = 1;
        $cnv_option->{archive}   = 1;
        $cnv_option->{compress}  = 1;
    }
    if($sync_option) {
        my @options = split / /, $sync_option;
        for (@options) {
            $_ =~ s/-//g;
            if($_ =~ m/=/) {
                my ($key, $value) = split /=/, $_;
                $cnv_option->{$key} = [] unless defined $cnv_option->{$key};
                push @{$cnv_option->{$key}}, $value;
            } else {
                $cnv_option->{$_} = 1;
            }
        }
    }
    return $cnv_option;
}

sub exec_ssh {
    my ($self, $identity_file, $user, $host, $src, $dest, $sync_option) = @_;
    my $ssh = Net::OpenSSH->new(
        $host,
        (
            user     => $user,
            key_path => $identity_file,
        ),
    );
    $ssh->error and die "Can't ssh to ". $host .": " . $ssh->error;

    # rsync
    if($self->mode eq 'put') {
        $ssh->rsync_put($sync_option, $src, $dest) or die "rsync failed: " . $ssh->error;
    } else {
        $ssh->rsync_get($sync_option, $src, $dest) or die "rsync failed: " . $ssh->error;
    }
}

1;

