package Yogafire::CommandClass::SSH;
use Mouse;
has ec2           => ( is  => "rw" );
has config        => ( is  => "rw" );
has opt           => ( is  => "rw" );

has port          => ( is  => "rw" );
has user          => ( is  => "rw" );
has identity_file => ( is  => "rw" );
has proxy         => ( is  => "rw" );
has sync_option   => ( is  => "rw", default => sub { {} });
no Mouse;

use Net::OpenSSH;
use Yogafire::Instance qw/list/;

sub BUILD {
    my $self = shift;

    $self->port($self->opt->{port} || $self->config->get('ssh_port') || '22');
    $self->user($self->opt->{user} || $self->config->get('ssh_user') || '');
    $self->identity_file($self->opt->{identity_file} || $self->config->get('identity_file') || '');

    if($self->opt->{sync_option}) {
        $self->sync_option($self->parse_option());
    }

    if($self->opt->{proxy}) {
        $self->opt->{tagsname} = $self->opt->{proxy};
        my @proxy_servers = list($self->ec2, $self->opt);
        my $proxy_instance  = shift @proxy_servers;
        die "Not found proxy server.\n" unless $proxy_instance;

        $self->proxy($proxy_instance)
    }

    return $self;
}

sub build_proxy_command {
    my $self = shift;
    my @proxy_cmd;
    if($self->proxy) {
        @proxy_cmd = ('ssh', '-W %h:%p', '-i', $self->identity_file, '-l', $self->user, $self->proxy->ipAddress);
    }
    return join(' ', @proxy_cmd);
}

sub build_raw_ssh_command {
    my ($self, $instance) = @_;
    my @cmd;
    if($self->proxy) {
        my $host = $instance->privateIpAddress;
        @cmd = ('ssh', '-p', $self->port, '-i', $self->identity_file, '-l', $self->user, '-oProxyCommand="', $self->build_proxy_command(), '"', $host);
    } else {
        my $host = $instance->ipAddress;
        @cmd = ('ssh', '-p', $self->port, '-i', $self->identity_file, '-l', $self->user, $host);
    }
    return join(' ', @cmd);
}

sub parse_option {
    my ($self) = @_;

    my $sync_option = $self->opt->{sync_option};
    my $cnv_option = {};
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

sub ssh {
    my ($self, $opt) = @_;

    my $host          = $opt->{host};
    my $src           = $opt->{src};
    my $dest          = $opt->{dest};
    my $timeout       = $opt->{timeout};
    my $proxy_cmd     = $self->build_proxy_command();

    my %ssh_options = (
        user     => $self->user,
        port     => $self->port,
        key_path => $self->identity_file,
    );
    if($timeout) {
        $ssh_options{timeout}             = $timeout;
        $ssh_options{kill_ssh_on_timeout} = $timeout;
    }
    if($proxy_cmd) {
        $ssh_options{proxy_command} = $proxy_cmd;
    }

    my $ssh = Net::OpenSSH->new(
        $host,
        %ssh_options,
    );
    $ssh->error and die "Can't ssh to ". $host .": " . $ssh->error;

    return $ssh;
}

sub target_host {
    my ($self, $instance) = @_;
    return ($self->proxy) ? $instance->privateIpAddress : $instance->ipAddress;
}

1;
