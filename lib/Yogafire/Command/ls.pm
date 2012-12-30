package Yogafire::Command::ls;
use Mouse;

extends qw(Yogafire::CommandBase);

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
    documentation   => "specified instance status (running / stopped)",
);
has tagsname => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "n",
    documentation   => "specified instance tagsname.",
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

use Yogafire::Instance qw/list display_list display_table/;
use Yogafire::Instance::Action;
use Yogafire::Term;

sub abstract {'EC2 List Instance'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga ls [-?] <tagsname>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # tags name filter
    my $tagsname = $args->[0];
    $opt->{tagsname} = $tagsname if $tagsname;

    my @instances = list($self->ec2, $opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    my $column_list = $self->config->get('instance_column');
    if($opt->{interactive} || !$opt->{notable}) {
        display_table(\@instances, $column_list);
    } else {
        display_list(\@instances, $column_list, $opt->{interactive});
    }

    if($opt->{interactive}) {
        my @ng_name = $self->ng_name(\@instances);
        my $ia = Yogafire::Instance::Action->new(ec2 => $self->ec2, config => $self->config);
        my $term = Yogafire::Term->new('Input Number');
        $term->set_completion_word( [ map { $_->tags->{Name}, $_->instanceId} @instances ] );

        while (1) {
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

            # show action
            $ia->action_print($target_instance, $opt);
            last;
        }
    }
}

1;
