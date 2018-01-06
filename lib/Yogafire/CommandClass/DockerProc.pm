package Yogafire::CommandClass::DockerProc;
use Mouse;
has opt         => ( is  => "rw" );
has interactive => ( is  => "rw" );
has instance    => ( is  => "rw" );
has host        => ( is  => "rw" );
has yoga_ssh    => ( is  => "rw" );
has ssh         => ( is  => "rw" );
no Mouse;

use Yogafire::Term;
use Yogafire::Docker;
use Yogafire::CommandClass::DockerSSH;

sub BUILD {
    my $self = shift;

    my $yoga_ssh = Yogafire::CommandClass::DockerSSH->new(
        {
            opt => $self->opt,
        }
    );

    my $host = $yoga_ssh->target_host($self->instance);
    my $ssh = $yoga_ssh->ssh(
        {
            host    => $host,
        }
    );
    $self->host($host);
    $self->yoga_ssh($yoga_ssh);
    $self->ssh($ssh);

    return $self;
}

sub search {
    my ($self) = @_;

    # capture
    my $out = $self->ssh_docker_ps();
    # docker class
    my $y_docker = Yogafire::Docker->new();
    $y_docker->set_container_data_with_capture($out);

    my $term = Yogafire::Term->new();
    $term->set_completion_word([map {$_[$#_]} @{$y_docker->cache}]);

    # args filter
    my $container_filter = $self->opt->{'docker-container-filter'};
    if ($container_filter) {
        my @target_containers = $y_docker->search_from_cache($container_filter);
        $y_docker->cache(\@target_containers);
    }

    if(scalar @{$y_docker->cache} == 0) {
        die "Not Found Container. \n";
    } elsif($self->interactive && scalar @{$y_docker->cache} == 1) {
        return $y_docker->cache->[0]; 
    }

    while (1) {
        # display
        $y_docker->output();
        return unless $self->interactive;

        # confirm
        my $input = $term->readline("no / id / image / name > ");
        $input =~ s/^ //g;
        $input =~ s/ $//g;
        last if $input =~ /^(q|quit|exit)$/;
        next unless $input;

        my $target_container = $y_docker->cache->[$input-1] if $input && $input =~ /^\d+$/;
        $target_container ||= $y_docker->find_from_cache(qr/^$input$/);
        if ($target_container) {
            # run action
            return $target_container;
        } else {
            my @target_containers = $y_docker->search_from_cache(qr/$input/);
            if(scalar @target_containers == 1) {
                # run action
                return $target_containers[0];
            } elsif(scalar @target_containers > 0) {
                $y_docker->cache(\@target_containers);
            }
        }
    }
};

sub ssh_docker_ps {
    my ($self) = @_;
    my $docker_cmd = 'docker ps --format "table {{.ID}}||{{.Image}}||{{.Command}}||{{.RunningFor}}||{{.Status}}||{{.Names}}"';
    # capture
    my ($out, $err) = $self->ssh->capture2($docker_cmd);
    $self->ssh->error and die "remote command failed: " . $self->ssh->error ." ". $err;

    return $out
}

sub ssh_docker_logs {
    my ($self, $container, $tail) = @_;
    my $container_id = $container->[0];

    if($tail) {
        $tail = '-f';
    } else {
        $tail = '';
    }
    my $docker_cmd = "docker logs $tail $container_id";
    my ($in, $out, $pid) = $self->ssh->open2({tty => 1}, $docker_cmd);
    while (<$out>) { print }
    kill TERM => $pid;
    waitpid $pid, 0;
    close $in;
    close $out;
}

sub ssh_docker_exec {
    my ($self, $container, $docker_command) = @_;
    my $container_id = $container->[0];

    my $ssh_cmd = $self->yoga_ssh->build_raw_dockerssh_command($self->instance);
    my $docker_cmd = " docker exec -it $container_id $docker_command";
    my $cmd = "$ssh_cmd $docker_cmd";
    $self->exec_ssh($cmd) unless $self->opt->{retry};

    # retry
    while (1) {
        # check ssh connection
        eval { $self->ssh({ host => $self->host }); };
        $self->exec_ssh($cmd) unless $@;

        #warn $@;
        sleep 10;
    }
}

sub exec_ssh {
    my ($self, $ssh_cmd) = @_;
    print "$ssh_cmd\n";
    exec($ssh_cmd);
}

1;
