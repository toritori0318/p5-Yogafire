package Yogafire::CommandBase;
use strict;
use warnings;
use Mouse;
extends qw(MouseX::App::Cmd::Command);
no Mouse;

use Yogafire::Instance qw/list display_list display_table/;
use Yogafire::Instance::Action;
use Yogafire::Config;
use Yogafire::Term;

use File::stat;
use VM::EC2;

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

    my %params = (
        -access_key     => $aws_access_key_id,
        -secret_key     => $aws_secret_access_key,
        -raise_error    => 1,
    );
    if($region) {
        $params{'-placement_zone'} = $region;
        $params{'-endpoint'}       = "https://ec2.${region}.amazonaws.com";
    }

    VM::EC2->new(%params);
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->validate_args_common($opt, $args );
};

sub validate_args_common {
    my ($self, $opt, $args) = @_;

    # help
    die $self->usage if $opt->{help_flag};

    # illegal option
    for (@$args) {
        $self->usage_error("$_: illegal option.") if $_ =~ /^-/;
    }

    #
    if(ref $self ne 'Yogafire::Command::config' && !-e $self->config->file) {
        die sprintf("Can't find config file [%s]\nPlease excecute \"yoga config --init\"\n", $self->config->file);
    }

    # permission check
    if(-e $self->config->file) {
        my $stat_inf = stat($self->config->file);
        my $mode_8 = sprintf("%04o", $stat_inf->mode & 07777);
        if ($mode_8 ne '0600') {
            die sprintf("bad permissions: [%s][%s]\nPlease change the permissions to 0600\n", $self->config->file, $mode_8);
        }
    }
};

sub action_process {
    my ($self, $action_name, $opt ) = @_;
    $opt ||= {};

    my $ia = Yogafire::Instance::Action->new(ec2 => $self->ec2, config => $self->config);
    my $ia_action = $ia->action($action_name);
    my $state = $ia_action->state;

    $opt->{state} = $state unless $opt->{state};

    my @instances = list($self->ec2, $opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    } elsif(scalar @instances == 1) {
        return $ia_action->run(\@instances, $opt);
    }

    my @ng_name = $self->ng_name(\@instances);
    my $term = Yogafire::Term->new('Input Number');
    $term->set_completion_word([map {$_->tags->{Name}} @instances]);

    while (1) {
        # display
        $self->display_instances(\@instances, $opt);

        my @target_instances;
        if($opt->{force}) {
            @target_instances = @instances;
        } else {
            # confirm
            my $input = $term->readline('no / tags_Name / instance_id > ');
            $input =~ s/^ //g;
            $input =~ s/ $//g;
            last if $input =~ /^(q|quit|exit)$/;

            my $target_instance = $self->find_name(\@instances, $input);
            $target_instance ||= $self->find_id(\@instances, $input);
            $target_instance ||= $instances[$input-1] if $input && $input =~ /^\d+$/;
            if (!$target_instance) {
                print "Invalid Value. \n";
                next;
            }
            if ($target_instance && grep { $_ eq $input } @ng_name) {
                print "'Name' has been duplicated. Please use the 'no or instance_id' instead. \n";
                next;
            }
            push @target_instances, $target_instance;
        }

        # run action
        $ia_action->run(\@target_instances, $opt);

        # for loop
        last unless $opt->{loop};

        my $term = Yogafire::Term->new();
        my $yn = $term->ask_yn(
            prompt   => "\ncontinue OK? > ",
            default  => 'y',
        );
        last unless $yn;
    }
}

sub display_instances {
    my ($self, $instances, $opt) = @_;
    my $column_list = $self->config->get('instance_column');
    display_table($instances, $column_list);
}

sub find_name {
    my ($self, $instances, $name ) = @_;
    for my $instance (@$instances) {
        return $instance if $instance->tags->{Name} && $instance->tags->{Name} eq $name;
    }
}

sub find_id {
    my ($self, $instances, $instance_id ) = @_;
    for my $instance (@$instances) {
        return $instance if $instance->instanceId eq $instance_id;
    }
}

sub ng_name {
    my ($self, $instances) = @_;
    my @names = grep { $_ if $_ } map { $_->tags->{Name} } @$instances;
    my %sum_name;
    $sum_name{$_}++ for @names;
    return grep { $sum_name{$_} > 1 } keys %sum_name;
}

1;

