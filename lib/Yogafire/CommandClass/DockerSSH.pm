package Yogafire::CommandClass::DockerSSH;
use Mouse;
use Yogafire::CommandClass::SSH;
extends 'Yogafire::CommandClass::SSH';

use Yogafire::Term;

sub build_raw_dockerssh_command {
    my ($self, $instance) = @_;
    my $host = '';
    my @cmd = ('ssh', '-t', '-p', $self->port, '-i', $self->identity_file, '-l', $self->user);
    if($self->proxy) {
        $host = Yogafire::Util::get_target_host($instance, '1');
        push @cmd, ('-oProxyCommand="', $self->build_proxy_command(), '"');
    } else {
        $host = Yogafire::Util::get_target_host($instance);
    }
    push @cmd, $host;

    return join(' ', @cmd);
}

1;
