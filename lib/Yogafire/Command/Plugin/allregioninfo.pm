package Yogafire::Command::Plugin::allregioninfo;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has all => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show all",
);
has instance  => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show instance",
);
has image  => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show AMI",
);
has volume => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show Volume",
);
has snapshot => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show Snapshot",
);
has group => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show Security Group",
);
has address => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show Elastic Address",
);

no Mouse;

use Yogafire::Declare qw/ec2 config/;

sub abstract {'All Region Info'}
sub command_names {'all-region-info'}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $cmd = shift @$args;

    my $owner_id = ec2->account_id;

    # 指定がなければinstance only
    unless(%$opt) {
        $opt->{instance} = 1;
    }
    if($opt->{all}) {
        $opt->{$_} = 1 for (qw/instance image volume snapshot group address/);
    }

    my @regions = ec2->describe_regions();
    for my $region (@regions) {

        printf "%s %s %s\n", '='x16, $region, '='x16;

        ec2->endpoint("https://" . $region->regionEndpoint ."/");

        # instances
        if($opt->{instance}) {
            my @instances = ec2->describe_instances();
            if(scalar @instances > 0 ){
                print  "  instances\n";
                printf "    %-20s %-20s %s \n", $_->tags->{Name}||'', $_->instance_id, $_->instanceState for @instances;
            }
        }

        # images
        if($opt->{image}) {
            my @images = ec2->describe_images(-owner => $owner_id);
            if(scalar @images > 0 ){
                print  "  images\n";
                printf "    %-20s %-20s %-20s %s \n", $_->tags->{Name}||'', $_->name, $_->imageId, $_->imageState for @images;
            }
        }

        # volumes
        if($opt->{volume}) {
            my @volumes = ec2->describe_volumes();
            if(scalar @volumes > 0 ){
                print  "  volumes\n";
                printf "    %-20s %-20s %-20s %s \n", $_->tags->{Name}||'', $_->volumeId, $_->snapshotId, $_->status for @volumes;
            }
        }

        # snapshots
        if($opt->{snapshot}) {
            my @snapshots = ec2->describe_snapshots(-owner => $owner_id);
            if(scalar @snapshots > 0 ){
                print  "  snapshots\n";
                printf "    %-20s %-20s %-20s %s \n", $_->tags->{Name}||'', $_->snapshotId, $_->volumeId, $_->status for @snapshots;
            }
        }

        # Security Groups
        if($opt->{group}) {
            my @groups = ec2->describe_security_groups();
            if(scalar @groups > 0 ){
                print  "  security groups\n";
                printf "    %-20s %-20s \n", $_->groupName, $_->groupId for @groups;
            }
        }

        # Elastic Address
        if($opt->{address}) {
            my @addresses = ec2->describe_addresses();
            if(scalar @addresses > 0 ){
                print  "  addresses\n";
                printf "    %-20s %-20s %s \n", $_->publicIp, $_->allocationId||'', $_->instanceId for @addresses;
            }
        }

        print "\n";
    }
}

1;
