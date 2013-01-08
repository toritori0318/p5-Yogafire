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

use Yogafire::Term;

sub run {
    my ($self, $image, $opt) = @_;

    my ($input, $name) = $self->confirm_launch_instance($image, $opt);
    return unless $input;

    print "Launch instance start... \n";
    my @instances = $image->run_instances( %$input );
    if($name) {
        $_->add_tags(Name => $name) for @instances;
    }
    print "Launch instance in process. \n";

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

    my $instance_type_name = '';

    my $term = Yogafire::Term->new();

    unless($count) {
        print "\n";
        $count = $term->get_reply(
            prompt   => 'Launch Count > ',
            allow    => qr/\d+/,
            default  => 1,
        );
    }

    my @select_instance_type = (
        { type => 't1.micro',   name => 'Micro Instance', },
        { type => 'm1.small',   name => 'Small Instance', },
        { type => 'm1.medium',  name => 'Medium Instance', },
        { type => 'm1.large',   name => 'Large Instance', },
        { type => 'm1.xlarge',  name => 'Extra Large Instance', },
        { type => 'm2.xlarge',  name => 'High-Memory Extra Large Instance', },
        { type => 'm2.2xlarge', name => 'High-Memory Double Extra Large Instance', },
        { type => 'm2.4xlarge', name => 'High-Memory Quadruple Extra Large Instance', },
        { type => 'c1.medium',  name => 'High-CPU Medium Instance', },
        { type => 'c1.xlarge',  name => 'High-CPU Extra Large Instance', },
    );

    unless($instance_type) {
        print "\n";
        $instance_type_name = $term->get_reply(
            prompt   => 'Instance Type List > ',
            choices  => [map {$_->{name}} @select_instance_type],
            default  => 'Micro Instance',
        );
        $instance_type = (map { $_->{type} } grep { $_->{name} eq $instance_type_name } @select_instance_type)[0];
    } else {
        $instance_type_name = (map { $_->{name} } grep { $_->{type} eq $instance_type } @select_instance_type)[0];
    }

    unless($availability_zone) {
        print "\n";
        my @select_zone = $self->ec2->describe_availability_zones({ state=>'available' });
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
        my @select_keypairs = $self->ec2->describe_key_pairs();
        $keypair = $term->get_reply(
            prompt   => 'Keypair List > ',
            choices  => [map {$_->keyName} @select_keypairs],
            default  => $select_keypairs[0]->keyName,
        );
    }

    if(scalar @groups == 0) {
        print "\n";
        my @select_groups = $self->ec2->describe_security_groups();
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
    Instance Type : $instance_type_name ($instance_type)
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
    return (\%args, $name);
};

1;
