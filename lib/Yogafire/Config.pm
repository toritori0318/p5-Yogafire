package Yogafire::Config;
use strict;
use warnings;

use YAML::Tiny;
use File::HomeDir;
use File::Spec;
use Amazon::Credentials qw{set_sso_credentials get_role_credentials};

use Yogafire::Term;

my $config_file = do {
    if($ENV{YOGAFIRE_CONFIG}) {
        File::Spec->catfile($ENV{YOGAFIRE_CONFIG});
    } else {
        File::Spec->catfile(File::HomeDir->my_home, '.yoga');
    }
};

my $aws_config_file = do {
    File::Spec->catfile(File::HomeDir->my_home, '.aws/config');
};

use Mouse;
has 'file'   => (is => 'rw', isa => 'Str', default => $config_file );
has 'config' => (is => 'rw');
has 'current_profile' => (is => 'rw', default => 'global');
has 'common_class' => (is => 'rw', isa => 'Bool');
no Mouse;

sub BUILD {
    my $self = shift;

    if($self->common_class) {
        $self->set_dummy_config();
    } else {
        $self->set_config();
    }

    return $self;
}

sub set_config {
    my ($self) = @_;

    my $yaml;
    if(-e $self->file) {
        $yaml = YAML::Tiny->read( $self->file );
    }

    my $profile = $self->current_profile;
    unless($profile) {
	if ($ENV{'AWS_PROFILE'}) {
            $profile = $ENV{'AWS_PROFILE'};
        }elsif ($yaml->[0]) {
            $profile = $yaml->[0]->{use_profile};
	}
	$profile ||= 'default';
    }

    my $use_config = {};
    # slurp config
    if($yaml && $yaml->[0]) {
	my ($yoga_global_config, $profile_config) = ({}, {});
	# first load _yoga_default config
        if($yaml->[0]->{'_yoga_default'}) {
	    $yoga_global_config = $yaml->[0]->{'_yoga_default'} || {};
        }
	# next load profile config
        if($yaml->[0]->{$profile}) {
	    $profile_config = $yaml->[0]->{$profile} || {};
        }
	# merge
	my %merge= (%$yoga_global_config, %$profile_config);
        $use_config = \%merge;
    }

    # note: Environment variables have the highest priority.
    if($ENV{'AWS_ACCESS_KEY_ID'} && $ENV{'AWS_SECRET_ACCESS_KEY'}) {
	# set cred
        $use_config->{access_key_id}     = $ENV{'AWS_ACCESS_KEY_ID'};
        $use_config->{secret_access_key} = $ENV{'AWS_SECRET_ACCESS_KEY'};
        $use_config->{region}            = $ENV{'AWS_DEFAULT_REGION'};
    }

    # If there is no aws_cred in the env, get aws_config.
    # note: AWS config have the lowest priority.
    unless($use_config->{access_key_id} && $use_config->{secret_access_key} && $use_config->{region}) {
        my $aws_ini = Config::Tiny->read($aws_config_file);
        my $section;
        if ($aws_ini->{$profile}) {
            $section = $aws_ini->{$profile};
        } elsif ($aws_ini->{"profile $profile"}) {
            $section = $aws_ini->{"profile $profile"};
        }

        if ($section) {
	    my $cred;
	    my $region;
            # sso token
            if ($section->{sso_start_url}) {
                $region = $section->{sso_region} ||= $use_config->{region};
                my $sso_role_name  = $section->{sso_role_name};
                my $sso_account_id = $section->{sso_account_id};
                if (!$sso_role_name || !$sso_account_id || !$region) {
                    die "sso aws/config section not found [$profile][$sso_role_name][$sso_account_id][$region]\n";
                }

                set_sso_credentials($sso_role_name, $sso_account_id, $region);
                $cred = get_role_credentials(role_name  => $sso_role_name,
                                             account_id => $sso_account_id,
                                             region     => $region);
            } else {
                $cred = Amazon::Credentials->new({ profile => $profile });
            }

            if($cred) {
                # set cred
                $use_config->{access_key_id}     = $cred->{accessKeyId} || $cred->credential_keys->{AWS_ACCESS_KEY_ID} unless $use_config->{access_key_id};
                $use_config->{secret_access_key} = $cred->{secretAccessKey} || $cred->credential_keys->{AWS_SECRET_ACCESS_KEY} unless $use_config->{secret_access_key};
                $use_config->{security_token}    = $cred->{sessionToken} || $cred->credential_keys->{AWS_SESSION_TOKEN} unless $use_config->{security_token};
                $use_config->{region}            = $cred->{region} || $region unless $use_config->{region};
            }
        }
    }

    my $config = [
	{
	    "$profile" => $use_config,
	}
    ];

    $self->config($config);
    $self->current_profile($profile);
}

sub set_dummy_config {
    my ($self) = @_;

    my $config;
    my $profile = 'global';
    if(-e $self->file) {
        $config = YAML::Tiny->read( $self->file );
        $profile = $config->[0]->{use_profile} || $profile;
    } else {
        $config = YAML::Tiny->new();
    }
    # initial profile
    $config->[0]->{use_profile} = $profile;
    $config->[0]->{$profile} = {};

    $self->config($config);
    $self->current_profile($profile);

    # write file
    unless(-e $self->file) {
        $config->write($config_file);
        chmod(0600, $config_file);
    }
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
    my $section = $self->get_yoga_profile($profile);
    unless($section) {
        $section = $self->get_aws_profile($profile);
        unless($section) {
            die " Fail! invalid profile [$profile]\n";
        }
    }
    return $section;
}

sub get_yoga_profile {
    my ($self, $profile) = @_;
    return $self->config->[0]->{$profile};
}

sub get_aws_profile {
    my ($self, $profile) = @_;
    my $aws_ini = Config::Tiny->read($aws_config_file);
    my $aws_profile = sprintf("profile %s", $profile);
    return $aws_ini->{$aws_profile};
}

sub write_profile {
    my ($self, $profile) = @_;

    $self->config->[0]->{use_profile} = $profile;
    $self->config->write($self->file);

    return ($self->config->[0]->{$profile}) ? $self->config->[0]->{$profile} : 0;
}

sub switch_use_profile {
    my ($self, $profile) = @_;

    if(-e $self->file) {
        my $yaml = YAML::Tiny->read( $self->file );
        $self->config($yaml);
    }

    $self->config->[0]->{$profile} ||= {};
    $self->config->[0]->{use_profile} = $profile;
    $self->config->write($self->file);

    return ($self->config->[0]->{$profile}) ? $self->config->[0]->{$profile} : 0;
}

sub get {
    my ($self, $key) = @_;
    my $profile = $self->current_profile;
    return '' unless $profile;

    return $self->config->[0]->{$profile}->{$key};
}

sub trim_aws_profile {
    my ($self, $profile) = @_;
    $profile =~ s/\[aws\] //g;
    return $profile;
}

sub list_profile {
    my ($self) = @_;
    return { map { $_ => $self->config->[0]->{$_} } grep { $_ ne 'use_profile' } keys %{$self->config->[0]} };
}

sub list_aws_profile {
    my ($self) = @_;
    my $aws_ini = Config::Tiny->read($aws_config_file);
    return { map { $_ =~ s/profile/[aws_profile]/; $_ => $aws_ini->{$_} } keys %{$aws_ini} };
}

sub list_merge_profile {
    my ($self) = @_;
    my %merge= (%{$self->list_profile}, %{$self->list_aws_profile});
    return \%merge;
}

1;
