package Yogafire::Command::lsami;
use Mouse;

extends qw(Yogafire::Command Yogafire::CommandAttribute);

has interactive => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "i",
    documentation   => "interactive mode.",
);
has state => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "s",
    documentation   => "specified instance status (available / pending / failed)",
);
has filter => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "f",
    documentation   => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
);
has notable => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "does not display of the table style.",
);
no Mouse;

use Yogafire::Image qw/list display_list display_table/;
use Yogafire::Image::Action;
use Yogafire::Term;

sub abstract {'Image List'}
sub command_names {'ls-ami'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga ls-ami [-?] <name>';
    $self->{usage}->text;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    die "Please set the 'owner_id' attributes of the config.\n\n" . $self->usage
         unless $self->config->get('owner_id');
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $owner_id = $self->config->get('owner_id') || '';
    $opt->{owner_id} = $owner_id;

    # name filter
    my $name = $args->[0];
    $opt->{name} = $name if $name;

    my @images = list($self->ec2, $opt);
    if(scalar @images == 0) {
        print "Not Found Image. \n";
        return;
    }

    my $column_list = $self->config->get('image_column');
    if($opt->{interactive} || !$opt->{notable}) {
        display_table(\@images, $column_list);
    } else {
        display_list(\@images, $column_list, $opt->{interactive});
    }

    if($opt->{interactive}) {
        my $ia = Yogafire::Image::Action->new(ec2 => $self->ec2, config => $self->config);
        my $term = Yogafire::Term->new('Input Number');
        while (1) {
            my $input = $term->readline('  Input No > ');
            last if $input =~ /^(q|quit|exit)$/;

            if ($input !~ /^\d+$/ || !$images[$input-1]) {
                print "Invalid Number. \n";
                next;
            }
            $ia->confirm($images[$input-1]);
            last;
        }

    }
}

sub describe_images {
    my ($self, $image) = @_;


    $image   = $self->ec2->describe_images(-image_id => $image->imageId);

    my $state   = $image->imageState;
    my $owner   = $image->imageOwnerId;
    my $rootdev = $image->rootDeviceName;
    my @devices = $image->blockDeviceMapping;
    my $tags    = $image->tags;

    my $term = Yogafire::Term->new();

    print "\n";
    my $count = $term->get_reply(
        print_me => 'Launch Count.',
        prompt   => '> ',
        allow    => qr/\d+/,
        default  => 1,
    );

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

    print "\n";
    my $instance_type_name = $term->get_reply(
        print_me => 'Instance Type List.',
        prompt   => '> ',
        choices  => [map {$_->{name}} @select_instance_type],
        default  => 'Micro Instance',
    );
    my $instance_type = (map { $_->{type} } grep { $_->{name} eq $instance_type_name } @select_instance_type)[0];

    print "\n";
    my @select_zone = $self->ec2->describe_availability_zones({ state=>'available' });
    push @select_zone, ' ';
    my $availability_zone = $term->get_reply(
        print_me => 'Availability Zone List.',
        prompt   => '> ',
        choices  => \@select_zone,
        default  => ' ',
    );
    $availability_zone =~ s/ //;

    print "\n";
    my $name = $term->get_reply(
        print_me => 'Instance Name.',
        prompt   => '> ',
    );
    $name ||= '';

    print "\n";
    my @select_keypairs = $self->ec2->describe_key_pairs();
    my $keypair = $term->get_reply(
        print_me => 'Keypair List.',
        prompt   => '> ',
        choices  => [map {$_->keyName} @select_keypairs],
        default  => $select_keypairs[0]->keyName,
    );

    print "\n";
    my @select_groups = $self->ec2->describe_security_groups();
    my @groups = $term->get_reply(
        print_me => 'Security Group List. (put them on one line, separated by blanks)',
        prompt   => '> ',
        choices  => [map {$_->groupName} @select_groups],
        multi    => 1,
    );

    my $confirm_str =<<"EOF";
================================================================
Instance Info

     Launch Count : $count
    Instance Type : $instance_type_name ($instance_type)
Availability Zone : $availability_zone
             Name : $name
          Keypair : $keypair
   Security Group : @groups
================================================================
EOF

    my $bool = $term->ask_yn(
        print_me => $confirm_str,
        prompt   => 'Launch Ok ? ',
        default  => 'y',
    );
    return unless $bool;

    my %args = (
        -max_count      => $count,
        -instance_type  => $instance_type,
        -placement_zone => $availability_zone,
        -key_name       => $keypair,
        -security_group => \@groups,
    );
    $args{'-placement_zone'} = $availability_zone if $availability_zone;

    print "Launsh instance start... \n";
    my @instances = $image->run_instances( %args );
    if($name) {
        $_->add_tags(Name => $name) for @instances;
    }
    print "Launsh instance in process. \n";
}

1;
