package Yogafire::Command::Instance::cmd;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has filter => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
);
has concurrency => (
    traits        => [qw(Getopt)],
    isa           => "Int",
    is            => "rw",
    cmd_aliases   => "c",
    documentation => "Number of multiple processes.",
);
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
    documentation   => "specified proxy server name(ip or dns or instance_id or tagsname).",
);
has timeout => (
    traits        => [qw(Getopt)],
    isa           => "Int",
    is            => "rw",
    cmd_aliases   => "t",
    documentation => "Number of ssh timeout. (default: 30)",
);


no Mouse;

use Net::OpenSSH;
use Parallel::ForkManager;
use Yogafire::Logger;
use Yogafire::Instance;
use Yogafire::Term;
use Yogafire::Declare qw/ec2 config/;

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

    my $timeout = $opt->{timeout} || 30;

    my $y_ins = Yogafire::Instance->new();

    my $host   = shift @$args;
    my $cmd    = shift @$args;

    my $condition = {};
    $condition->{host}  = $host;
    $condition->{state} = 'running';

    my @instances = $y_ins->search($condition);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    if($opt->{'dry-run'}) {
        printf "======== dry run mode =========\n";
        printf "======== command = %s\n", $cmd;
    }

    my $concurrency = $opt->{concurrency} || 1;
    my $pm = Parallel::ForkManager->new($concurrency);

    for my $instance (@instances) {
        my $pid = $pm->start and next;

        my $yoga_ssh = Yogafire::CommandClass::SSH->new(
            {
                opt    => $opt,
            }
        );

        my $name = $instance->tags->{Name} || '';
        my $host = $yoga_ssh->target_host($instance);
        my $results;
        unless ($opt->{'dry-run'}) {
            # exec ssh
            my $ssh = $yoga_ssh->ssh(
                {
                    host    => $host,
                    timeout => $timeout,
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

        yinfo(resource => $instance, message => '============== Command Log Start ==============');
        print $results;
        print "\n";
        yinfo(resource => $instance, message => '============== Command Log End ==============');

        $pm->finish;
    }

    $pm->wait_all_children;
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

