package Yogafire::Command::Plugin::updateec2tags;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has tagsname => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "t",
    documentation   => "specified instance tagsname.",
);
has filter => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "f",
    documentation   => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
);
has key => (
    traits          => [qw(Getopt)],
    isa             => "ArrayRef",
    is              => "rw",
    cmd_aliases     => "k",
    documentation   => "specified update tags key(=value). (ex. --key='Name=www[% seqno %]'",
);
has force => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "force execute.",
);

no Mouse;

use Yogafire::Instance;
use Yogafire::Declare qw/ec2 config/;
use Yogafire::Util;

sub abstract {'Update EC2 Tags'}
sub command_names {'update-ec2-tags'}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    $self->usage_error('<key> option is required.')
         unless $opt->{key};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $y_ins = Yogafire::Instance->new();
    $y_ins->out_columns(config->get('instance_column')) if config->get('instance_column');
    $y_ins->out_format($opt->{format} || 'table');

    # tags name filter
    my $tagsname = $args->[0];
    $opt->{tagsname} = $tagsname if $tagsname;

    my @instances = $y_ins->search($opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    $opt ||= {};
    my $keyvalue = $opt->{key} || [];
    my $force    = $opt->{force};

    my $tags = Yogafire::Util::key_eq_value_to_hash($keyvalue);

    unless($force) {
        my $column_list = config->get('instance_column');
        $y_ins->output();

        my $term = Yogafire::Term->new();
        my $yn = $term->ask_yn(
            prompt   => "Update all the displayed instance. OK? > ",
            default  => 'n',
        );
        return unless $yn;
    }

    print "[Start] Update Tags. \n";
    # update tags
    my $seqno = 1;
    for my $instance (@instances) {
        for my $key (keys %{$tags}) {
            my $value = $tags->{$key};
            $value =~ s/\[% seqno %\]/$seqno/;
            $instance->add_tags($key => $value);
        }
        $seqno++;
    }
    print "[End] Update Tags. \n";
}

1;
