package Yogafire::CommandClass::InstanceProc;
use Mouse;
has opt         => ( is  => "rw" );
has action      => ( is  => "rw" );
has force       => ( is  => "rw" );
has interactive => ( is  => "rw" );
has loop        => ( is  => "rw" );
has yogafire    => ( is  => "rw" );
no Mouse;

use LWP::UserAgent;
use Yogafire::Instance;
use Yogafire::Instance::Action;
use Yogafire::Term;
use Yogafire::Declare qw/ec2 config/;

sub action_process {
    my ($self) = @_;
    my $action_name = $self->action;
    my $opt         = $self->opt || {};

    # instance class
    my $y_ins = Yogafire::Instance->new();
    $y_ins->out_columns(config->get('instance_column')) if config->get('instance_column');
    $y_ins->out_format($opt->{format} || 'table');

    # action class
    my $ia = Yogafire::Instance::Action->new(
        action_name  => $action_name,
    );
    $opt->{state} = $ia->state if $ia->state && !$opt->{state};

    # search
    my @instances = $y_ins->search($opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    } elsif(scalar @instances == 1 && $ia->action_class) {
        $ia->procs(\@instances, $opt);
        return;
    }

    # force
    if($self->force && $ia->action_class) {
        return $ia->procs(\@instances, $opt);
    }

    my $term = Yogafire::Term->new();
    $term->set_completion_word([map {$_->tags->{Name}} @instances]);

    while (1) {
        # display
        $y_ins->output();
        return unless $self->interactive;

        # confirm
        my $yogafire = ($self->{yogafire}) ? '/ ("yogafire" is all target)': '';
        my $input = $term->readline("no / tags_Name / instance_id ${yogafire}> ");
        $input =~ s/^ //g;
        $input =~ s/ $//g;
        last if $input =~ /^(q|quit|exit)$/;
        next unless $input;

        my $target_instance = $y_ins->find_from_cache({ name => qr/^$input$/ });
        $target_instance  ||= $y_ins->find_from_cache({ id   => qr/^$input$/ });
        $target_instance  ||= $y_ins->cache->[$input-1] if $input && $input =~ /^\d+$/;
        if (!$target_instance) {
            my @target_instances = $y_ins->search_from_cache({ name => qr/$input/ });
            if(scalar @target_instances == 0) {
                if($self->{yogafire} && $input eq 'yogafire') {
                    # all target
                    $opt->{force} = 1;
                    $ia->procs($y_ins->cache, $opt);
                    $opt->{force} = 0;
                    last;
                } else {
                    print "Invalid Value. \n";
                }
            } elsif(scalar @target_instances == 1) {
                # run action
                $ia->procs($target_instances[0], $opt);
            } else {
                $y_ins->cache(\@target_instances);
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

sub self_process {
    my ($self) = @_;
    my $action_name = $self->action;
    my $opt         = $self->opt || {};

    # instance class
    my $y_ins = Yogafire::Instance->new();
    $y_ins->out_columns(config->get('instance_column')) if config->get('instance_column');
    $y_ins->out_format($opt->{format} || 'table');

    # action class
    my $ia = Yogafire::Instance::Action->new(
        action_name  => $action_name,
    );

    my $instance = $self->get_self_instance();
    unless($instance) {
        die "Not Found Instance. \n";
    }

    # run action
    $ia->procs($instance, $opt);
}

sub get_self_instance {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(5);
    my $response = $ua->get('http://169.254.169.254/latest/meta-data/instance-id');
    return unless $response->is_success;

    my $instance_id = $response->decoded_content;
    my @instances = ec2->describe_instances($instance_id);
    return shift @instances;
}

1;

