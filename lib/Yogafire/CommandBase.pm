package Yogafire::CommandBase;
use strict;
use warnings;
use Mouse;
extends qw(MouseX::App::Cmd::Command);
no Mouse;

use Yogafire::Config;
use Yogafire::Term;

use File::stat;
use VM::EC2;

{
    our $EC2;
    sub ec2 { $EC2 }
    sub set_ec2 { $EC2 = $_[1] }
}

{
    our $CONFIG;
    sub config { $CONFIG }
    sub set_config { $CONFIG = $_[1] }
}

sub BUILD {
    my ($self) = @_;
    my $config = Yogafire::Config->new;
    $self->set_config($config);
}

sub vmec2 {
    my ($self) = @_;
    # Config取得
    my $aws_access_key_id     = config->get('access_key_id');
    my $aws_secret_access_key = config->get('secret_access_key');
    my $identity_file         = config->get('identity_file');
    my $region                = config->get('region');
    return unless $aws_access_key_id;

    my %params = (
        -access_key     => $aws_access_key_id,
        -secret_key     => $aws_secret_access_key,
        -raise_error    => 1,
    );
    if($region) {
        $params{'-placement_zone'} = $region;
        $params{'-endpoint'}       = "https://ec2.${region}.amazonaws.com";
    }

    VM::EC2->new(%params);
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->validate_args_common($opt, $args );
};

sub validate_args_common {
    my ($self, $opt, $args) = @_;

    # help
    die $self->usage if $opt->{help_flag};

    # illegal option
    for (@$args) {
        $self->usage_error("$_: illegal option.") if $_ =~ /^-/;
    }

    my $file = config->file;
    #
    if(ref $self ne 'Yogafire::Command::Common::config' && !-e $file) {
        die sprintf("Can't find config file [%s]\nPlease excecute \"yoga config --init\"\n", $file);
    }

    # permission check
    if(-e $file) {
        my $stat_inf = stat($file);
        my $mode_8 = sprintf("%04o", $stat_inf->mode & 07777);
        if ($mode_8 ne '0600') {
            die sprintf("bad permissions: [%s][%s]\nPlease change the permissions to 0600\n", $file, $mode_8);
        }
    }

    # profile
    if($opt->{profile} && config->get_profile($opt->{profile})) {
        $self->config->current_profile($opt->{profile});
        $self->set_ec2(vmec2());
    }
    # set ec2
    $self->set_ec2(vmec2()) if $self->config;
};

1;

