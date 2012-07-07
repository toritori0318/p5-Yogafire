package Yogafire::Plugin::Command::hosts;
use Mouse;
extends qw(Yogafire::Command Yogafire::CommandAttribute);
has replace => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "r",
    documentation => "replace hosts file.",
);
has backup => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "b",
    documentation => "backup hosts file. (with <replace> option)",
);
has 'private-ip' => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    cmd_aliases   => "p",
    documentation => "private IP address to the ip address of the hosts file.",
);
has 'hosts-file' => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "specify hosts file path. (default: /etc/hosts )",
);
no Mouse;

use File::Copy qw/copy/;
use Text::Diff 'diff';
use Yogafire::Instance qw/list/;
use Time::Piece;

sub abstract {'Operation for hosts file'}

sub begin {qq{#======== Yogafire Begen ========#\n}}
sub end   {qq{#======== Yogafire End   ========#\n}}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $ip_key = ($opt->{'private-ip'}) ? 'privateIpAddress' : 'ipAddress';

    my @instances = list($self->ec2, $opt);
    # name & ip is required.
    @instances = grep { $_->tags->{Name} && $_->{data}->{$ip_key} } @instances;

    if(scalar @instances == 0) {
        print "Not Found Instance. \n";
        return;
    }

    my $begin = $self->begin;
    my $end   = $self->end;

    my $hosts_file = '/etc/hosts';
    if($opt->{'hosts-file'}) {
        $hosts_file = $opt->{'hosts-file'};
    }

    open my $rfh, '<', $hosts_file;
    my $org_data = do{ local $/; <$rfh>};
    my $new_data = $org_data;
    if ( $new_data !~ /$begin/) {
        $new_data .= sprintf("\n%s%s", $self->begin, $self->end);
    }

    my $hosts = $self->_hosts(\@instances, $ip_key);
    $new_data =~ s/${begin}(.*)${end}/${begin}${hosts}${end}/sg;
    #print $new_data;
    close $rfh;

    if($opt->{replace}) {
        my $diff = diff(\$new_data, \$org_data);
        unless($diff) {
            print "hosts file is no different.\n";
            return;
        }

        # backup
        if($opt->{backup}) {
            my $save_hosts_file = $hosts_file. '.'. Time::Piece->new->strftime("%Y%m%d%H%M%S");
            copy $hosts_file, $save_hosts_file or die "Can't copy file . [$hosts_file]->[$save_hosts_file]";
            print " backup hosts file -> $save_hosts_file\n";
        }

        # replace file
        open my $wfh, '>', $hosts_file or die "Can't open file. [$hosts_file]";
        print $wfh $new_data;
        close $wfh;

        print "Complete replacement hosts file.\n";
    } else {
        print $new_data;
    }
}

sub _hosts {
    my ( $self, $instances, $ip_key ) = @_;
    my $replace_hosts = '';
    for (@$instances) {
        my $name        = $_->tags->{Name};
        my $ip          = $_->{data}->{$ip_key};
        $replace_hosts .= sprintf ("%-16s %s\n" , $ip, $name);
    }
    return $replace_hosts;
}

1;
