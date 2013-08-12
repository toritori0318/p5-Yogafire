package Yogafire::Image::Action::RunInstance;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'runinstance');
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
use Yogafire::Util;

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
    my $instance_type     = $opt->{type};
    my $availability_zone = $opt->{availability_zone};
    my $name              = $opt->{name};
    my $keypair           = $opt->{keypair};
    my @groups            = ($opt->{a_groups}) ? @{$opt->{a_groups}} : ();
    my $force             = $opt->{force};
    my %tags              = ($opt->{h_tags}) ? %{$opt->{h_tags}} : ();
    if($name && !exists $tags{Name}) {
        $tags{Name} = $name;
    }

    my $term = Yogafire::Term->new();

    unless($force) {
        my $default = $count || 1;
        print "\n";
        $count = $term->get_reply(
            prompt   => 'Launch Count > ',
            allow    => qr/\d+/,
            default  => $count,
        );
    }

    my $y_instance_types = Yogafire::InstanceTypes->new();
    my $instance_types = $y_instance_types->instance_types;
    unless($force) {
        my $default = $instance_type || 't1.micro';
        print "\n";
        $instance_type = $term->get_reply(
            prompt   => 'Instance Type List > ',
            choices  => [map { $_->{id} } @$instance_types],
            default  => $default,
        );
    }

    unless($force) {
        my $default = $availability_zone || ' ';
        print "\n";
        my @select_zone = ec2->describe_availability_zones({ state => 'available' });
        push @select_zone, ' ';
        $availability_zone = $term->get_reply(
            prompt   => 'Availability Zone List > ',
            choices  => \@select_zone,
            default  => $default,
        );
        $availability_zone =~ s/ //;
    }

    unless($force) {
        my $default = $tags{Name} || '';
        print "\n";
        $name = $term->get_reply(
            prompt   => 'Instance Name > ',
            default  => $default,
        );
        $name ||= '';
    }
    my %itags;
    unless($force) {
        for my $key (keys %tags) {
            next if $key eq 'Name';

            my $default = $tags{$key} || '';
            print "\n";
            $itags{$key} = $term->get_reply(
                prompt   => "Tags [$key] > ",
                default  => $default,
            );
            $itags{$key} ||= '';
        }
    }

    unless($force) {
        print "\n";
        my @select_keypairs = ec2->describe_key_pairs();
        my $default = $keypair;
        $keypair = $term->get_reply(
            prompt   => 'Keypair List > ',
            choices  => [map {$_->keyName} @select_keypairs],
            default  => $default,
        );
    }

    if(scalar @groups > 0) {
        my @select_groups = ec2->describe_security_groups(
            -group_name => \@groups
        );
        # validation
        if (scalar @select_groups != scalar @groups) {
            @groups = ();
        }
    }
    if(!$force && scalar @groups == 0) {
        print "\n";
        my @select_groups = ec2->describe_security_groups();
        @groups = $term->get_reply(
            prompt   => 'Security Group List. (put them on one line, separated by blanks) > ',
            choices  => [map {$_->groupName} @select_groups],
            multi    => 1,
        );
    }

    my $disp_tags = join("\n", map { sprintf("    %s=%s", $_, $itags{$_}) } keys %itags);
    if($disp_tags) {
        $disp_tags = "\nTagKey Info\n$disp_tags";
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
$disp_tags
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
    return (\%args, \%tags);
};

1;
