package Yogafire::Config;
use strict;
use warnings;

use YAML::Tiny;
use File::HomeDir;
use File::Spec;

use Yogafire::Term;

my $config_file = do {
    if($ENV{YOGAFIRE_CONFIG}) {
        File::Spec->catfile($ENV{YOGAFIRE_CONFIG});
    } else {
        File::Spec->catfile(File::HomeDir->my_home, '.yoga');
    }
};

use Mouse;
has 'file'   => (is => 'rw', isa => 'Str', default => $config_file );
has 'config' => (is => 'rw');
has 'current_profile' => (is => 'rw');
no Mouse;

sub BUILD {
    my $self = shift;

    unless(-e $self->file) {
        return undef;
    }

    $self->set_config();

    return $self;
}

sub set_config {
    my ($self) = @_;

    my $yaml = YAML::Tiny->read( $self->file );

    my $profile = $yaml->[0]->{use_profile} || 'global';
    $yaml->[0]->{$profile}->{identity_file} ||= '';
    $yaml->[0]->{$profile}->{region}        ||= '';
    $yaml->[0]->{$profile}->{ssh_user}      ||= '';
    $yaml->[0]->{$profile}->{ssh_port}      ||= '';

    $self->config($yaml);

    # initial profile
    $self->current_profile($profile);
}

sub init {
    my ($self, $opt) = @_;

    my $config = YAML::Tiny->new();

    my $term = Yogafire::Term->new();

    # access_key_id, secret_access_key
    my ($access_key_id, $secret_access_key);
    if($ENV{AWS_CREDENTIAL_FILE}) {
        open my $fh, "<", $ENV{AWS_CREDENTIAL_FILE};
        if($fh) {
            while(<$fh>) {
                chomp;
                my ($key, $value) = split /=/, $_;
                $access_key_id     = $value if $key eq 'AWSAccessKeyId';
                $secret_access_key = $value if $key eq 'AWSSecretKey';
            }
            close $fh;
        } else {
            printf "Can't open file %s\n", $ENV{AWS_CREDENTIAL_FILE};
        }
    } elsif($ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY}) {
        $access_key_id     = $ENV{AWS_ACCESS_KEY_ID};
        $secret_access_key = $ENV{AWS_SECRET_ACCESS_KEY};
    }
    my $region        = $ENV{EC2_REGION};
    my $user          = 'ec2-user';
    my $port          = '22';
    my $identity_file = '';

    unless($opt->{noconfirm}) {
        print "\n";
        $access_key_id = $term->get_reply(
            prompt   => 'AWS Access Key Id? > ',
            default  => $access_key_id,
        ) || '';
        $secret_access_key = $term->get_reply(
            prompt   => 'AWS Secret Access Key? > ',
            default  => $secret_access_key,
        ) || '';
        $region = $term->get_reply(
            prompt   => 'Region? > ',
            default  => $region,
        ) || '';
        $user = $term->get_reply(
            prompt   => 'SSH User? > ',
            default  => $user,
        ) || '';
        $port = $term->get_reply(
            prompt   => 'SSH Port? > ',
            default  => $port,
        ) || '';
        $identity_file = $term->get_reply(
            prompt   => 'SSH Identity File? > ',
        ) || '';

        my $confirm_str =<<"EOF";
================================================================
Config File Info

    AWS Access Key Id : $access_key_id
AWS Secret Access Key : $secret_access_key
               Region : $region
             SSH User : $user
             SSH Port : $port
    SSH Identity File : $identity_file
================================================================
EOF
        print "\n";
        my $bool = $term->ask_yn(
            print_me => $confirm_str,
            prompt   => 'Create Config File OK? ',
        );
        exit unless $bool;
    }

    # init
    unlink $self->file;

    $config->[0]->{use_profile} = 'global';
    $config->[0]->{global}->{access_key_id} = $access_key_id;
    $config->[0]->{global}->{secret_access_key} = $secret_access_key;
    $config->[0]->{global}->{region} = $region;
    $config->[0]->{global}->{ssh_user} = $user;
    $config->[0]->{global}->{ssh_port} = $port;
    $config->[0]->{global}->{identity_file} = $identity_file;

    # instance_column
    $config->[0]->{global}->{instance_column} = [
        qw/
            tags_Name
            instanceId
            ipAddress
            privateIpAddress
            launchTime
            colorfulInstanceState
        /
    ];

    # image_column
    $config->[0]->{global}->{image_column} = [
        qw/
            tags_Name
            name
            imageId
            colorfulImageState
        /
    ];

    # write
    $config->write($config_file);

    # chmod
    chmod(0600, $config_file);
}

sub get_profile {
    my ($self, $profile) = @_;
    my $section = $self->config->[0]->{$profile};
    unless($section) {
        die " Fail! invalid profile [$profile]\n";
    }
    return $section;
}

sub write_profile {
    my ($self, $profile) = @_;

    $self->config->[0]->{use_profile} = $profile;
    $self->config->write($self->file);

    $self->set_config;

    return ($self->config->[0]->{$profile}) ? $self->config->[0]->{$profile} : 0;
}

sub get {
    my ($self, $key) = @_;
    my $profile = $self->current_profile;
    return '' unless $profile;

    return $self->config->[0]->{$profile}->{$key};
}

sub list_profile {
    my ($self) = @_;
    return { map { $_ => $self->config->[0]->{$_} } grep { $_ ne 'use_profile' } keys %{$self->config->[0]} };
}

1;
