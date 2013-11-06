package Yogafire::CommandClass::VpcProc;
use Mouse;
has opt         => ( is  => "rw" );
has action      => ( is  => "rw" );
has force       => ( is  => "rw" );
has interactive => ( is  => "rw" );
has loop        => ( is  => "rw" );
has multi       => ( is  => "rw" );
no Mouse;

use LWP::UserAgent;
use Yogafire::Vpc;
use Yogafire::Vpc::Action;
use Yogafire::Term;
use Yogafire::Declare qw/ec2 config/;

sub action_process {
    my ($self) = @_;
    my $action_name = $self->action;
    my $opt         = $self->opt || {};

    # instance class
    my $y_vpc = Yogafire::Vpc->new();
    $y_vpc->out_columns(config->get('vpc_column')) if config->get('vpc_column');
    $y_vpc->out_format($opt->{format} || 'table');

    # action class
    my $ia = Yogafire::Vpc::Action->new(
        action_name  => $action_name,
    );

    # search
    my @vpcs = $y_vpc->search($opt);
    if(scalar @vpcs == 0) {
        die "Not Found Vpc. \n";
    } elsif($action_name && scalar @vpcs == 1) {
        $ia->procs(\@vpcs, $opt) if $ia->action_class;
        return;
    }

    # force
    if($self->force && $ia->action_class) {
        return $ia->procs(\@vpcs, $opt);
    }

    my $term = Yogafire::Term->new();
    $term->set_completion_word([map {$_->tags->{Name}} @vpcs]);

    while (1) {
        # display
        $y_vpc->output();
        return unless $self->interactive;

        # confirm
        my $yogafire = ($self->multi) ? '/ ("yogafire" is all target)': '';
        my $input = $term->readline("no / tags_Name / instance_id ${yogafire}> ");
        $input =~ s/^ //g;
        $input =~ s/ $//g;
        last if $input =~ /^(q|quit|exit)$/;
        next unless $input;

        my $target_instance = $y_vpc->find_from_cache({ name => qr/^$input$/ });
        $target_instance  ||= $y_vpc->find_from_cache({ id   => qr/^$input$/ });
        $target_instance  ||= $vpcs[$input-1] if $input && $input =~ /^\d+$/;
        if (!$target_instance) {
            my @target_vpcs = $y_vpc->search_from_cache({ name => qr/$input/ });
            if(scalar @target_vpcs == 0) {
                if($self->multi && $input eq 'yogafire') {
                    # all target
                    $opt->{force} = 1;
                    $ia->procs($y_vpc->cache, $opt);
                    $opt->{force} = 0;
                    last;
                } else {
                    print "Invalid Value. \n";
                }
            } elsif(scalar @target_vpcs == 1) {
                # run action
                $ia->procs($target_vpcs[0], $opt);
            } else {
                $y_vpc->cache(\@target_vpcs);
            }
            next;
        }

        # run action
        $ia->procs($target_instance, $opt);

        # for loop
        last unless $self->loop;

        my $term = Yogafire::Term->new();
        my $yn = $term->ask_yn(
            prompt   => "\ncontinue OK? > ",
            default  => 'y',
        );
        last unless $yn;
    }
}

1;
