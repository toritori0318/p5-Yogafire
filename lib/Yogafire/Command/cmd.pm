package Yogafire::Command::cmd;
use Mouse;
extends qw(Yogafire::CommandBase);
has filter => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
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
has password => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "p",
    documentation => "send sudo password.",
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
use Yogafire::Term;

sub abstract {'Execute remote command'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga cmd [-?] <tagsname> <cmd>';
    $self->{usage}->text;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "<tagsname> and <cmd> is required.\n\n" . $self->usage
        if scalar @$args < 2;
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $tagsname = shift @$args;
    my $cmd      = shift @$args;

    # tags name filter
    $opt->{tagsname} = $tagsname if $tagsname;
    $opt->{state}    = 'running';

    my @instances = list($self->ec2, $opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    if($opt->{'dry-run'}) {
        printf "======== dry run mode =========\n";
        printf "======== command = %s\n", $cmd;
    }

    for (@instances) {
        my $name = $_->tags->{Name} || '';
        my $results;
        unless ($opt->{'dry-run'}) {
            $results = $self->exec_ssh(
                {
                    identity_file   => $self->config->get('identity_file'),
                    user            => $self->config->get('ssh_user'),
                    host            => $_->dns_name,
                    cmd             => $cmd,
                    sudo            => $opt->{sudo},
                    f_passwaord     => $opt->{password},
                }
            );
        }
        printf "# Connected to %s@%s(%s)\n%s", $self->config->get('ssh_user'), $_->ip_address, $name, $results || '';
    }
}

my $g_password = '';
sub exec_ssh {
    my ($self, $args) = @_;

    my $identity_file = $args->{identity_file} ||'';
    my $user          = $args->{user} ||'';
    my $host          = $args->{host} ||'';
    my $cmd           = $args->{cmd} ||'';
    my $sudo          = $args->{sudo} ||'';
    my $f_passwaord   = $args->{f_passwaord};

    my $ssh = Net::OpenSSH->new(
        $host,
        (
            user                => $user,
            key_path            => $identity_file,
            timeout             => 10,
            kill_ssh_on_timeout => 10,
        ),
    );
    $ssh->error and die "Can't ssh to ". $host .": " . $ssh->error;

    my $password;
    my ($out, $err);
    if($sudo) {
        my $ssh_params = {};
        if($f_passwaord) {
            if($g_password) {
                $password = $g_password;
            } else {
                my $term = Yogafire::Term->new();
                $password = $term->mask_password();
            }
            $ssh_params = { stdin_data => "$password\n" };
        }
        # execute ssh
        ($out, $err) = $ssh->capture2(
            $ssh_params,
            join(' ', 'sudo', '-Sk', $cmd),
        );
    } else {
        # execute ssh
        ($out, $err) = $ssh->capture2($cmd);
    }

    $ssh->error and die "remote command failed: " . $ssh->error ." ". $err;

    # reuse password
    $g_password = $password;

    return $out;
}

1;
