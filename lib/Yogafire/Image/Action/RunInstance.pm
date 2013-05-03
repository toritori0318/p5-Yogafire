package Yogafire::Image::Action::RunInstance;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'run instance');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/available pending failed/],
    },
);
no Mouse;

use Yogafire::Logger;
use Yogafire::Term;
use Yogafire::InstanceTypes;
use Yogafire::Declare qw/ec2 config/;

sub proc {
    my ($self, $image, $opt) = @_;

    my ($input, $tags) = $self->confirm_launch_instance($image, $opt);
    return unless $input;

    yinfo(resource => $image, message => "<<<Start>>> Launch instance.");
    my @instances = $image->run_instances( %$input );
    if($tags && scalar (keys %$tags) > 0 ) {
        for my $instance (@instances) {
            # waiting status
            while ($instance->current_state ne 'running') { sleep 3; }
            for my $key (keys %$tags) {
                $instance->add_tags($key => $tags->{$key});
            }
        }
    }
    yinfo(resource => $image, message => "<<<End>>> Launch instance in process.");

};

sub confirm_launch_instance {
    my ($self, $image, $opt) = @_;
    $opt ||= {};

    my $count             = $opt->{count};
    my $instance_type     = $opt->{instance_type};
    my $availability_zone = $opt->{availability_zone};
    my $name              = $opt->{name};
    my $keypair           = $opt->{keypair};
    my @groups            = ($opt->{groups}) ? @{$opt->{groups}} : ();
    my $force             = $opt->{force};
    my $tags              = $opt->{tags} || {};

    my $term = Yogafire::Term->new();

    unless($count) {
        print "\n";
        $count = $term->get_reply(
            prompt   => 'Launch Count > ',
            allow    => qr/\d+/,
            default  => 1,
        );
    }

    my $y_instance_types = Yogafire::InstanceTypes->new();
    my $instance_types = $y_instance_types->instance_types;
    unless($instance_type) {
        print "\n";
        $instance_type = $term->get_reply(
            prompt   => 'Instance Type List > ',
            choices  => [map { $_->{id} } @$instance_types],
            default  => 't1.micro',
        );
    }

    unless($availability_zone) {
        print "\n";
        my @select_zone = ec2->describe_availability_zones({ state => 'available' });
        push @select_zone, ' ';
        $availability_zone = $term->get_reply(
            prompt   => 'Availability Zone List > ',
            choices  => \@select_zone,
            default  => ' ',
        );
        $availability_zone =~ s/ //;
    }

    unless($name) {
        print "\n";
        $name = $term->get_reply(
            prompt   => 'Instance Name > ',
        );
        $name ||= '';
    }

    unless($keypair) {
        print "\n";
        my @select_keypairs = ec2->describe_key_pairs();
        $keypair = $term->get_reply(
            prompt   => 'Keypair List > ',
            choices  => [map {$_->keyName} @select_keypairs],
            default  => $select_keypairs[0]->keyName,
        );
    }

    if(scalar @groups == 0) {
        print "\n";
        my @select_groups = ec2->describe_security_groups();
        @groups = $term->get_reply(
            prompt   => 'Security Group List. (put them on one line, separated by blanks) > ',
            choices  => [map {$_->groupName} @select_groups],
            multi    => 1,
        );
    }

    my $confirm_str =<<"EOF";
================================================================
Launch Info

     Launch Count : $count
    Instance Type : $instance_type
Availability Zone : $availability_zone
             Name : $name
          Keypair : $keypair
   Security Group : @groups
================================================================
EOF

    unless($force) {
        my $bool = $term->ask_yn(
            print_me => $confirm_str,
            prompt   => 'Launch Ok ? ',
        );
        return unless $bool;
    }

    my %args = (
        -max_count      => $count,
        -instance_type  => $instance_type,
        -placement_zone => $availability_zone,
        -key_name       => $keypair,
        -security_group => \@groups,
    );
    $args{'-placement_zone'} = $availability_zone if $availability_zone;

    # tag
    my $return_tags = $tags;
    $return_tags->{Name} = $name;

    return (\%args, $return_tags);
};

1;
