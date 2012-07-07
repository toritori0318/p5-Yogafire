package Yogafire::Command::config;
use Mouse;

extends qw(Yogafire::Command Yogafire::CommandAttribute);

has init => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Initalize configuration file.",
);
has noconfirm => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "In without checking, create a file.",
);
has show => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show configuration file.",
);
has edit => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Start the editor to edit the configuration file.",
);
no Mouse;

sub abstract {'Yogafire Config Manager'}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "Please specify any option. <init / show / edit>\n\n" . $self->usage
        unless %$opt;
}

use Yogafire::Term;

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $ec2  = $self->ec2;
    my $config = $self->config;

    printf "======== config file : [%s] =========\n", $config->file;
    if($opt->{init}) {
        if(-e $config->file) {
            my $term = Yogafire::Term->new();
            my $yn = $term->ask_yn(
                prompt   => $config->file ." is exists. continue? > ",
                default  => 'n',
            );
            return unless $yn;
        }
        # init value
        $config->init($opt);
        printf " output config file : [%s]\n", $config->file;

    } elsif($opt->{edit}) {
        my $editor = $ENV{EDITOR} || '/usr/bin/vi';
        system($editor, $config->file);

    } elsif($opt->{show}) {
        $self->_cat_file($config->file);

    }

}

sub _cat_file {
    my ($file) = @_;
    open my $fh, '<', $file
        or die "Can't cat ". $file .": $!";
    while (<$fh>) { print $_; }
    close $fh;
}

1;
