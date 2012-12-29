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
    cmd_aliases     => "s",
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
    $self->{usage}->text;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # tags name filter
    my $tagsname = $args->[0];
    $opt->{tagsname} = $tagsname if $tagsname;

    my @instances = list($self->ec2, $opt);
    if(scalar @instances == 0) {
        print "Not Found Instance. \n";
        return;
    }

    my $column_list = $self->config->get('instance_column');
    if($opt->{interactive} || !$opt->{notable}) {
        display_table(\@instances, $column_list);
    } else {
        display_list(\@instances, $column_list, $opt->{interactive});
    }

    if($opt->{interactive}) {
        my $ia = Yogafire::Instance::Action->new(ec2 => $self->ec2, config => $self->config);
        my $term = Yogafire::Term->new('Input Number');
        while (1) {
            my $input = $term->readline('Input No > ');
            last if $input =~ /^(q|quit|exit)$/;

            if ($input !~ /^\d+$/ || !$instances[$input-1]) {
                print "Invalid Number. \n";
                next;
            }
            $ia->action_print($instances[$input-1]);
            last;
        }

    }
}

1;
