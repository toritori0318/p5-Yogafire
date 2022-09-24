package Yogafire::Instance::Action::SSMStart;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'ssmstart');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/running/],
    },
);
no Mouse;

use Yogafire::Instance qw/list/;
use Yogafire::CommandClass::SSH;
use POSIX qw(strftime);

sub proc {
    my ($self, $instance, $opt) = @_;
    my $cmd = $self->build_ssm_start_session_command($instance);
    exec($cmd);
};

sub build_ssm_start_session_command {
    my ($self, $instance) = @_;

    my $access_key = sprintf("AWS_ACCESS_KEY_ID=%s", $instance->aws->access_key || '');
    my $secret_key = sprintf("AWS_SECRET_ACCESS_KEY=%s", $instance->aws->secret || '');
    my $session_token = sprintf("AWS_SESSION_TOKEN=%s", $instance->aws->security_token || '');
    my $region = sprintf("AWS_DEFAULT_REGION=%s", $instance->aws->region || '');

    my @cmd = ($access_key, $secret_key, $session_token, $region, 'aws', 'ssm', 'start-session', '--target', $instance->instanceId);
    return join(' ', @cmd);
}

1;
