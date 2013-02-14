package Yogafire::Command::getnoopt;
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
    documentation => "rsync option (default-rsync-option: rsync  --archive --update --verbvose --compress)",
);
no Mouse;

use Yogafire::CommandClass::Sync;

sub abstract {'Rsync get file from remote. '}
sub command_names {'get-noopt'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga get [-?] <tagname or host> <from:remote_path> <to:local_path>';
    $self->{usage};
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "tagname(or host) / remote_path / local_path is required.\n\n" . $self->usage
        if scalar @$args != 3;
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    $opt  ||= {};
    my $default_option = 0;
    Yogafire::CommandClass::Sync->new(
        mode           => 'get',
        ec2            => $self->ec2,
        config         => $self->config,
        default_option => 0,
    )->execute($opt, $args, $default_option);
}

1;
