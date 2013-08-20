package Yogafire::Command::Plugin::hosts;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

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

use Yogafire::Instance;

use File::Copy qw/copy/;
use Text::Diff 'diff';
use DateTime;

sub abstract {'Operation for hosts file'}

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

    my $y_ins = Yogafire::Instance->new();

    my $ip_key = ($opt->{'private-ip'}) ? 'privateIpAddress' : 'ipAddress';

    my @instances = $y_ins->search($opt);
    # name & ip is required.
    @instances = grep { $_->tags->{Name} && $_->{data}->{$ip_key} } @instances;

    if(scalar @instances == 0) {
        print "Not Found Instance. \n";
        return;
    }

    my $begin = $self->begin;
    my $end   = $self->end;

    # filepath
    my $hosts_file = '/etc/hosts';
    if($opt->{'hosts-file'}) {
        $hosts_file = $opt->{'hosts-file'};
    }

    # slurp file
    open my $rfh, '<', $hosts_file;
    my $org_data = do{ local $/; <$rfh>};
    my $new_data = $org_data;
    if ( $new_data !~ /$begin/) {
        $new_data .= sprintf("\n%s%s", $self->begin, $self->end);
    }

    my $hosts = $self->_hosts(\@instances, $ip_key);
    $new_data =~ s/${begin}(.*)${end}/${begin}${hosts}${end}/sg;
    close $rfh;

    if($opt->{preview}) {
        print $new_data;
    } elsif($opt->{replace}) {
        # check diff
        my $diff = diff(\$new_data, \$org_data);
        unless($diff) {
            print "hosts file is no different.\n";
            return;
        }

        # backup
        if($opt->{backup}) {
            my $save_hosts_file = $hosts_file. '.'. DateTime->now->strftime("%Y%m%d%H%M%S");
            copy $hosts_file, $save_hosts_file or die "Can't copy file . [$hosts_file]->[$save_hosts_file]";
            print " backup hosts file -> $save_hosts_file\n";
        }

        # replace file
        open my $wfh, '>', $hosts_file or die "Can't open file. [$hosts_file]";
        print $wfh $new_data;
        close $wfh;

        print "Complete replacement hosts file.\n";
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
