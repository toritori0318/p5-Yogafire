package Yogafire::Command::putnoopt;
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
    documentation => "rsync option.",
);
no Mouse;

use Net::OpenSSH;
use Yogafire::Instance qw/list/;

sub abstract {'Rsync put local file to remote. '}
sub command_names {'put-noopt'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga put [-?] <tagname or host> <from:local_path> <to:remote_path>';
    $self->{usage};
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "tagname(or host) / local_path / remote_path is required.\n\n" . $self->usage
         if scalar @$args != 3;
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $default_option = 0;
    $opt  ||= {};
    Yogafire::CommandClass::Sync->new(
        mode           => 'put',
        ec2            => $self->ec2,
        config         => $self->config,
    )->execute($opt, $args, $default_option);
}

1;
