package Yogafire::Command::put;
use Mouse;

extends qw(Yogafire::CommandBase);

has 'dry-run'=> (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "dry run mode.",
);

has sync_option => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "o",
    documentation => "sync option",
);
no Mouse;

use Net::OpenSSH;
use Yogafire::Instance qw/list/;

sub abstract {'Rsync put local file to remote. '}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga put [-?] <tagname or host> <from:local_path> <to:remote_path>';
    $self->{usage}->text;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "tagname(or host) / local_path / remote_path is required.\n\n" . $self->usage
         if scalar @$args != 3;
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    $opt  ||= {};
    Yogafire::CommandClass::Sync->new(
        mode   => 'put',
        ec2    => $self->ec2,
        config => $self->config,
    )->execute($opt, $args);
}

1;
