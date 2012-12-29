package Yogafire::Command::cmd;
use Mouse;
extends qw(Yogafire::CommandBase);
has filter => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "api filter",
);
has multi => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "m",
    documentation => "enable multi server.",
);
#has parallel => (
#    traits        => [qw(Getopt)],
#    isa           => "Bool",
#    is            => "rw",
#    cmd_aliases   => "p",
#    documentation => "Run in parallel.",
#);
has sudo => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "s",
    documentation => "sudo command.",
);
has 'dry-run'=> (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "dry run mode.",
);


no Mouse;

use Net::OpenSSH;
use Yogafire::Instance qw/list/;

sub abstract {'Execute remote command'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga cmd [-?] <tagsname> <cmd>';
    $self->{usage}->text;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "<cmd> is required.\n\n" . $self->usage
        if scalar @$args < 2;
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $tagsname = shift @$args;
    my $cmd = shift @$args;

    # tags name filter
    $opt->{tagsname} = $tagsname if $tagsname;
    $opt->{state} = 'running';

    my @instances = list($self->ec2, $opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. ";
    } elsif(!$opt->{multi} && scalar @instances > 1) {
        die "Disable Multi Server. ";
    }

    if($opt->{'dry-run'}) {
        printf "======== dry run mode =========\n";
        printf "======== command = %s\n", $cmd;
    }

    for (@instances) {
        my $name = $_->tags->{Name} || '';
        my $results = [];
        unless ($opt->{'dry-run'}) {
            $results = $self->exec_ssh(
                {
                    identity_file => $self->config->get('identity_file'),
                    user          => $self->config->get('ssh_user'),
                    host          => $_->dns_name,
                    cmd           => $cmd,
                    sudo          => $opt->{sudo},
                }
            );
        }
        printf "# Connected to %s@%s(%s)\n%s", $self->config->get('ssh_user'), $_->ip_address, $name, join('', @$results) || '';
    }
}

sub exec_ssh {
    my ($self, $args) = @_;

    my $identity_file = $args->{identity_file} ||'';
    my $user          = $args->{user} ||'';
    my $host          = $args->{host} ||'';
    my $cmd           = $args->{cmd} ||'';
    my $sudo          = $args->{sudo} ||'';
    my $ssh = Net::OpenSSH->new(
        $host,
        (
            user     => $user,
            key_path => $identity_file,
            timeout => 10,
            kill_ssh_on_timeout => 10,
        ),
    );
    $ssh->error and die "Can't ssh to ". $host .": " . $ssh->error;

    my @results;
    {
        my $opt = {};
        my @cmds = ($cmd);
        if($sudo) {
            $opt->{tty} = 1;
        }
        @results = $ssh->capture(
            $opt,
            @cmds,
        );
        $ssh->error and die "remote command failed: " . $ssh->error;
    }

    return \@results || ();
}

1;
