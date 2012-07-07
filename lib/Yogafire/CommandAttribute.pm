package Yogafire::CommandAttribute;
use strict;
use warnings;
use Mouse;
no Mouse;

use VM::EC2;
use Yogafire::Config;

my ($vmec2, $config);

sub BUILD {
    my ($self) = @_;
    $config = Yogafire::Config->new;
    $vmec2 = vmec2() if $config->config;
}

sub ec2 { $vmec2; }
sub config { $config; }

sub vmec2 {
    # Config取得
    my $aws_access_key_id     = $config->get('access_key_id');
    my $aws_secret_access_key = $config->get('secret_access_key');
    my $identity_file         = $config->get('identity_file');
    my $region                = $config->get('region');
    return unless $aws_access_key_id;

    my $endpoint = "https://ec2.${region}.amazonaws.com";

    my $ec2 = VM::EC2->new(
        -access_key     => $aws_access_key_id,
        -secret_key     => $aws_secret_access_key,
        -placement_zone => $region,
        -endpoint       => $endpoint,
        -raise_error    => 1,
    );
}

1;
