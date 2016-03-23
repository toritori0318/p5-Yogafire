package Yogafire::Command::Plugin::summary;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

has filter => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "api filter. (ex.--filter='tag:keyname=value,instance-state-name=running')",
);
has 'summary-key' => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "k",
    documentation => "specified summary key. (ex.--summary-key='tag:Name' --summary-key='instanceType' )",
);
no Mouse;

use Yogafire::Instance;

sub abstract {'EC2 instance summary report'}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    $self->usage_error('<summary-key> option is required.')
         unless $opt->{'summary-key'};
}

my @headers = qw/summary-key count/;

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $summary_key = $opt->{'summary-key'};
    my $y_ins = Yogafire::Instance->new();

    my @instances = $y_ins->search($opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    my %report;
    for my $instance (@instances) {
        my $group_value;
        if ($summary_key =~ /^tags:(.*)/) {
            $group_value = $instance->tags->{$1};
        } else {
            $group_value = $instance->{data}->{$summary_key};
        };
        next unless $group_value;

        $report{$group_value} ||= 0;
        $report{$group_value}++;
    }

    # output report
    my $output = Yogafire::Output->new({ format => '' });
    $output->header(\@headers);
    my @rows = map { [$_, $report{$_}] } sort keys %report;
    $output->output(\@rows);
}

1;
