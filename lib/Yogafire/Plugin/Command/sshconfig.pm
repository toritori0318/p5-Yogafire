package Yogafire::Plugin::Command::sshconfig;
use Mouse;
extends qw(Yogafire::CommandBase);
has 'preview' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "p",
    documentation => "Show preview hosts file.",
);
has replace => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "r",
    documentation => "replace sshconfig file.",
);
has backup => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "b",
    documentation => "backup sshconfig file. (with <replace> option)",
);
has 'sshconfig-file' => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => 'specify sshconfig file path. (default: {$HOME}/.ssh/config )',
);
no Mouse;

use File::Copy qw/copy/;
use Text::Diff 'diff';
use Yogafire::Instance qw/list/;
use DateTime;

sub abstract {'Operation for sshconfig'}

sub begin {qq{#======== Yogafire Begen ========#\n}}
sub end   {qq{#======== Yogafire End   ========#\n}}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "Please specify any option. <preview / replace>\n\n" . $self->usage
        unless $opt->{preview} || $opt->{replace};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $ip_key = ($opt->{private}) ? 'privateIpAddress' : 'ipAddress';

    my @instances = list($self->ec2, $opt);
    # name & ip is required.
    @instances = grep { $_->tags->{Name} && $_->{data}->{$ip_key} } @instances;

    if(scalar @instances == 0) {
        print "Not Found Instance. \n";
        return;
    }

    my $begin = $self->begin;
    my $end   = $self->end;

    # filepath
    my $home_dir = $ENV{"HOME"};
    my $sshconfig_file = $home_dir."/.ssh/config";
    if($opt->{'sshconfig-file'}) {
        $sshconfig_file = $opt->{'sshconfig-file'};
    }

    # slurp file
    open my $rfh, '<', $sshconfig_file;
    my $org_data = do{ local $/; <$rfh>};
    my $new_data = $org_data;
    if ( $new_data !~ /$begin/) {
        $new_data .= sprintf("\n%s%s", $self->begin, $self->end);
    }

    my $hosts = $self->_sshconfig(\@instances, $opt->{private});
    $new_data =~ s/${begin}(.*)${end}/${begin}${hosts}${end}/sg;
    #print $new_data;
    close $rfh;

    if($opt->{preview}) {
        print $new_data;
    } elsif($opt->{replace}) {
        # check diff
        my $diff = diff(\$new_data, \$org_data);
        unless($diff) {
            print "sshconfig is no different.\n";
            return;
        }

        # backup
        if($opt->{backup}) {
            my $save_sshconfig_file = $sshconfig_file . '.'. DateTime->now->strftime("%Y%m%d%H%M%S");
            copy $sshconfig_file, $save_sshconfig_file or die "Can't copy file . [$sshconfig_file]->[$save_sshconfig_file]";
            print " backup sshconfig file -> $save_sshconfig_file\n";
        }

        # replace file
        open my $wfh, '>', $sshconfig_file or die "Can't open file. [$sshconfig_file]";
        print $wfh $new_data;
        close $wfh;

        print "Complete replacement sshconfig file.\n";
    }
}

sub _sshconfig {
    my ( $self, $instances ) = @_;

    my $config = $self->config;
    my $user     = $config->get('ssh_user');
    my $identity_file = $config->get('identity_file');
    my $ssh_port = $config->get('ssh_port');

    my $replace_hosts = '';
    for (@$instances) {
        my $name        = $_->tags->{Name};
        my $dns_name    = $_->dnsName;
        next unless $name;

        $replace_hosts .= sprintf ("Host %s\n" , $name);
        $replace_hosts .= sprintf ("    HostName     %s\n" , $dns_name);
        $replace_hosts .= sprintf ("    IdentityFile %s\n" , $identity_file);
        $replace_hosts .= sprintf ("    User         %s\n" , $user);
        $replace_hosts .= sprintf ("    Port         %s\n" , $ssh_port);
        $replace_hosts .= sprintf ("\n");
    }
    return $replace_hosts;
}

1;
