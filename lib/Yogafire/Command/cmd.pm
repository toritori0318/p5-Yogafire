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
    cmd_aliases   => "P",
    documentation => "send sudo password.",
);
has 'dry-run'=> (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "dry run mode.",
);
has user => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "u",
    documentation   => "specified login user",
);
has identity_file => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "i",
    documentation   => "specified identity file",
);
has port => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "p",
    documentation   => "specified port number",
);
has proxy => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    documentation   => "specified proxy server name(tagsname).",
);


no Mouse;

use Net::OpenSSH;
use Yogafire::Instance;
use Yogafire::Term;

sub abstract {'Execute remote command'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga cmd [-?] <tagsname> <cmd>';
    $self->{usage};
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "<tagsname> and <cmd> is required.\n\n" . $self->usage
        if scalar @$args < 2;
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $ec2    = $self->ec2;
    my $config = $self->config;

    my $y_ins = Yogafire::Instance->new({ ec2 => $ec2 });

    my $host   = shift @$args;
    my $cmd    = shift @$args;

    my $condition = {};
    if ($host =~ /^(\d+).(\d+).(\d+).(\d+)$/) {
        $condition->{filter} = ($1 == 10) ? "private-ip-address=$host" : "ip-address=$host";
    } else {
        $condition->{tagsname} = $host;
    }
    $condition->{state} = 'running';

    my @instances = $y_ins->search($condition);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    if($opt->{'dry-run'}) {
        printf "======== dry run mode =========\n";
        printf "======== command = %s\n", $cmd;
    }

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
        my $results;
        unless ($opt->{'dry-run'}) {
            # exec ssh
            my $ssh = $yoga_ssh->ssh(
                {
                    host    => $host,
                    timeout => 10,
                }
            );

            $results = $self->exec_cmd(
                $ssh,
                {
                    cmd             => $cmd,
                    sudo            => $opt->{sudo},
                    f_passwaord     => $opt->{password},
                }
            );
        }

        printf "# Connected to %s@%s(%s)\n%s", $self->config->get('ssh_user'), $host, $name, $results || '';
    }
}

my $g_password = '';
sub exec_cmd {
    my ($self, $ssh, $args) = @_;

    my $cmd           = $args->{cmd} ||'';
    my $sudo          = $args->{sudo} ||'';
    my $f_passwaord   = $args->{f_passwaord};

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
