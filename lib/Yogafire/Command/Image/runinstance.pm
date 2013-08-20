package Yogafire::Command::Image::runinstance;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

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
has count => (
    traits        => [qw(Getopt)],
    isa           => "Int",
    is            => "rw",
    cmd_aliases   => "n",
    documentation => "Number of launch instance.",
);
has type => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "t",
    documentation => "specified instance type.(ex: t1.micro / m1.small / ..)",
);
has availability_zone => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "z",
    documentation => "specified availablity zone.(ex: ap-northeast-1a / ap-northeast-1b,ap-northeast-1c)",
);
has tag => (
    traits          => [qw(Getopt)],
    isa             => "ArrayRef",
    is              => "rw",
    cmd_aliases     => "k",
    documentation   => "specified instance tags. (ex. --tag='Role=database'",
);
has keypair => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "k",
    documentation   => "specified keypair name.",
);
has groups => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "g",
    documentation   => "specified group name. (ex. --group='sg_base,sg_web'",
);
has user_data => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "d",
    documentation   => "specified user data. (ex. --user_data='echo Hello'",
);
has force => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "force execute.",
);
has vpc => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "vpc instance.",
);
has spot => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "spot instance.",
);
no Mouse;

use Yogafire::CommandClass::ImageProc;
use Yogafire::Util;

sub abstract {'Running Instance'}
sub command_names {'run-instance'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga launch <image-id> [-?]';
    $self->{usage};
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "<image-id> is required.\n\n" . $self->usage
        if scalar @$args < 1;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $image_id = shift @$args;
    $opt->{filter} = "image-id=$image_id";

    # convert tag
    if($opt->{tag} && scalar @{$opt->{tag}} > 0 ) {
        $opt->{h_tags} = Yogafire::Util::key_eq_value_to_hash($opt->{tag});
    }
    # convert group
    if($opt->{groups}) {
        $opt->{a_groups} = [split /,/, $opt->{groups}];
    }

    my $proc = Yogafire::CommandClass::ImageProc->new(
        {
            action       => 'runinstance',
            opt          => $opt,
            interactive  => 1,
        }
    );
    $proc->action_process();
}

1;
