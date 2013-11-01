package Yogafire::Command::Plugin::scaleec2;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has elb => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "e",
    documentation   => "specified name of the elastic load balancer name",
);
has scale_filter => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "T",
    documentation   => "specified tagname of the base instance name",
);
has count => (
    traits          => [qw(Getopt)],
    isa             => "Int",
    is              => "rw",
    cmd_aliases     => "c",
    documentation   => "specified update instance count",
);
has availability_zones => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "a",
    documentation   => "specified availability_zones(a/b/c) (ex. --availability_zones a,b,c)",
);

no Mouse;

use Yogafire::Instance;
use Yogafire::Declare qw/ec2 config/;
use Yogafire::Logger;

sub abstract {'Update EC2 Count'}
sub command_names {'scale-ec2'}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    $self->usage_error('<count> option is required.')
         unless $opt->{count};
    $self->usage_error('<scale_fileter> or <elb> option is required.')
         if !$opt->{scale_filter} && !$opt->{elb};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $y_ins = Yogafire::Instance->new();

    my $region = ec2->region;
    my $total_count = int($opt->{count});
    my @availability_zones = ($opt->{availability_zones}) ? map { ${region}.$_ } split /,/, $opt->{availability_zones} : () ;

    # zone check
    my @zones = ec2->describe_availability_zones(-filter => {state=>'available'});
    for my $z (@availability_zones) {
        die "Invalid availability zone [$z]\n" unless grep(/$z/, @zones);
    }

    my $elb;
    my @elb_instance_ids;
    my @instances;

    if($opt->{elb}) {
        # ELB
        $elb = $self->get_elb($opt->{elb});
        my @elb_instances = $elb->Instances();
        my @elb_instance_ids = map { $_->instanceId } @elb_instances;
        my @states = $elb->describe_instance_health(-instances => \@elb_instance_ids);
        for my $state (@states) {
            # Skip terminate instance
            next if $state->State eq 'OutOfService' && $state->Description eq 'Instance is in terminated state.';

            for my $elb_instance (@elb_instances) {
                if($elb_instance->instanceId eq $state->InstanceId) {
                    push @instances, $elb_instance;
                    last;
                }
            }
        }
    } else {
        # ec2 filter
        $opt->{filter} = $opt->{scale_filter};
        $opt->{state} = 'running';
        @instances = $y_ins->search($opt);
    }

    my $instance_count = scalar @instances;
    if($instance_count == 0) {
        die "Not Found Instance. \n";
    }

    my $diff_count = $total_count - $instance_count;
    warn "diff_count:[$diff_count]\n";
    if($diff_count == 0) {
        die "Not Updated. \n";
    } elsif($diff_count < 0) {
        warn "scale in instance\n";
        $diff_count = -$diff_count;
        my @ret_instance_ids = $self->terminate_instances(\@instances, $diff_count);
        # DeRegister ELB
        if($elb && scalar @ret_instance_ids > 0) {
            my @states = $elb->describe_instance_health(-instances => \@elb_instance_ids);
            my @terminated_instance_ids;
            for my $state (@states) {
                # Deregister terminate instance
                if($state->State eq 'OutOfService' && $state->Description eq 'Instance is in terminated state.') {
                    push @terminated_instance_ids, $state->InstanceId;
                }
            }
            warn "  Deregister instance id[$_]\n" for @terminated_instance_ids;
            $elb->deregister_instances(@terminated_instance_ids)
        }
        return;
    }

    # $diff_count > 0
    warn "scale out instance\n";
    my $scale_base_instance = $instances[0];
    if(scalar @availability_zones > 1) {
        # multi-az
        my @ret_instance_ids = $self->launch_instances_multi_az(
            $scale_base_instance,
            \@availability_zones,
            $diff_count,
            $total_count,
            $self->get_az_count(\@instances),
        );
        # Register ELB
        if($elb && scalar @ret_instance_ids > 0) {
            warn "  Register instance id[$_]\n" for @ret_instance_ids;
            $elb->register_instances('-instances' => @ret_instance_ids);
        }
    } else {
        # single-az
        my $zone = shift @availability_zones;
        my @ret_instance_ids = $self->launch_instances($scale_base_instance, $diff_count, $zone);
        # Register ELB
        if($elb && scalar @ret_instance_ids > 0) {
            warn "  Register instance id[$_]\n" for @ret_instance_ids;
            $elb->register_instances('-instances' => @ret_instance_ids);
        }
    }
}

sub get_elb {
    my ($self, $elb_name) = @_;
    my $elb = ec2->describe_load_balancers(-load_balancer_name => $elb_name);
    die "Not Found ELB.[".$elb."]" unless $elb;
    return $elb;
}

sub launch_instances {
    my ($self, $instance, $diff_count, $zone) = @_;
    my $tags = $instance->tags;

    # copy launch
    my %args = (
        -max_count      => $diff_count,
        -instance_type  => $instance->instanceType,
        -placement_zone => $zone || $instance->placement,
        -key_name       => $instance->keyPair,
        -security_group => [map {$_->{groupName}} @{$instance->{data}->{groupSet}->{item}}],
    );
    my $image = ec2->describe_images(-image_id => $instance->imageId);
    my @instances = $image->run_instances( %args );
    if($tags && scalar (keys %$tags) > 0 ) {
        for my $instance (@instances) {
            warn sprintf("Launch instance in single-az [%s] > [%s]. \n", $args{'-placement_zone'}, $args{'-max_count'});

            # waiting status
            while ($instance->current_state ne 'running') { sleep 3; }
            for my $key (keys %$tags) {
                $instance->add_tags($key => $tags->{$key});
            }
        }
    }
    return (map {$_->instanceId} @instances);
}

sub terminate_instances {
    my ($self, $instances, $diff_count) = @_;

    my @instance_ids;
    for my $instance (reverse @$instances) {
        push @instance_ids, $instance->instanceId;
        $instance->terminate;

        last if --$diff_count <= 0;
    }
    return \@instance_ids;
}


sub get_az_count {
    my ($self, $instances) = @_;

    my %az_count;
    for my $instance (@$instances) {
        # az毎カウント
        $az_count{$instance->placement} = 0 unless $az_count{$instance->placement};
        $az_count{$instance->placement}++;
    }
    return \%az_count;
}

sub launch_instances_multi_az {
    my ($self, $instance, $zones, $diff_count, $total_count, $az_counts) = @_;
    my $tags = $instance->tags;

    # copy launch
    my %args = (
        -max_count      => $total_count,
        -instance_type  => $instance->instanceType,
        -placement_zone => $instance->placement,
        -key_name       => $instance->keyPair,
        -security_group => [map {$_->{groupName}} @{$instance->{data}->{groupSet}->{item}}],
    );
    my $image = ec2->describe_images(-image_id => $instance->imageId);

    my %az_launch_count = map { $_ => 0 } @$zones;
    my $center_count    = int($total_count / scalar @$zones);
    my $surplus_count   = $total_count % scalar @$zones;
    # Decide the number of instances in each az
    for my $az (@$zones) {
        my $az_count          = $az_counts->{$az} || 0;
        my $launch_count      = $center_count - $az_count;
        $az_launch_count{$az} = $launch_count if $launch_count > 0;
        # surplus
        if($surplus_count > 0) {
            $az_launch_count{$az}++;
            $surplus_count--;
        }
    }

    my @instances;
    # Launch each az
    for my $az (@$zones) {
        $args{'-placement_zone'} = $az if $az;
        $args{'-max_count'}      = $az_launch_count{$az};
        next if $args{'-max_count'} <= 0;

        warn sprintf("Launch instance in multi-az [%s] > [%s]. \n", $args{'-placement_zone'}, $args{'-max_count'});
        @instances = $image->run_instances( %args );
        if($tags && scalar (keys %$tags) > 0 ) {
            for my $instance (@instances) {
                # waiting status
                while ($instance->current_state ne 'running') { sleep 3; }
                for my $key (keys %$tags) {
                    $instance->add_tags($key => $tags->{$key});
                }
            }
        }
    }
    return (map {$_->instanceId} @instances);
}

1;
