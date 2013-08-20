package Yogafire::Command::Image::lsami;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has interactive => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "i",
    documentation   => "interactive mode.",
);
has name => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "n",
    documentation   => "specified ami name.",
);
has state => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "s",
    documentation   => "specified ami status (available / pending / failed)",
);
has filter => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "f",
    documentation   => "api filter. (ex.--filter='name=value,state=available')",
);
has format => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "specified output format(default:table). (table / plain / json)",
);
has loop => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "l",
    documentation   => "Repeat without exit interactive mode.",
);
no Mouse;

use Yogafire::CommandClass::ImageProc;

sub abstract {'Image List'}
sub command_names {'ls-ami'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga ls-ami [-?] <name>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $name = $args->[0];
    $opt->{name} = $name if $name;

    $opt->{owner} = 'self';

    my $proc = Yogafire::CommandClass::ImageProc->new(
        {
            action       => undef,
            opt          => $opt,
            interactive  => $opt->{interactive},
            loop         => $opt->{loop},
        }
    );
    $proc->action_process();
}

1;
