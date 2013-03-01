package Yogafire::CommandClass::InstanceProc;
use Mouse;
has ec2         => ( is  => "rw" );
has config      => ( is  => "rw" );
has opt         => ( is  => "rw" );
has action      => ( is  => "rw" );
has force       => ( is  => "rw" );
has interactive => ( is  => "rw" );
has loop        => ( is  => "rw" );
no Mouse;

use LWP::UserAgent;
use Yogafire::Instance;
use Yogafire::Instance::Action;
use Yogafire::Term;

sub action_process {
    my ($self) = @_;
    my $action_name = $self->action;
    my $opt         = $self->opt || {};

    # instance class
    my $y_ins = Yogafire::Instance->new();
    $y_ins->ec2($self->ec2);
    $y_ins->out_columns($self->config->get('instance_column')) if $self->config->get('instance_column');
    $y_ins->out_format($opt->{format} || 'table');

    # action class
    my $ia = Yogafire::Instance::Action->new(
        ec2          => $self->ec2,
        config       => $self->config,
        action_name  => $action_name,
    );
    $opt->{state} = $ia->state if $ia->state && !$opt->{state};

    # search
    my @instances = $y_ins->search($opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    } elsif(scalar @instances == 1) {
        $ia->run(\@instances, $opt) if $ia->action_class;
        return;
    }

    # force
    if($self->force && $ia->action_class) {
        return $ia->run(\@instances, $opt);
    }

    my $term = Yogafire::Term->new();
    $term->set_completion_word([map {$_->tags->{Name}} @instances]);

    while (1) {
        # display
        $y_ins->output();
        return unless $self->interactive;

        # confirm
        my $input = $term->readline('no / tags_Name / instance_id > ');
        $input =~ s/^ //g;
        $input =~ s/ $//g;
        last if $input =~ /^(q|quit|exit)$/;
        next unless $input;

        my $target_instance = $y_ins->find_from_cache({ name => qr/^$input$/ });
        $target_instance  ||= $y_ins->find_from_cache({ id   => qr/^$input$/ });
        $target_instance  ||= $instances[$input-1] if $input && $input =~ /^\d+$/;
        if (!$target_instance) {
            my @target_instances = $y_ins->search_from_cache({ name => qr/$input/ });
            if(scalar @target_instances == 0) {
                print "Invalid Value. \n";
            } else {
                $y_ins->instances(\@target_instances);
            }
            next;
        }

        # run action
        $ia->run($target_instance, $opt);

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
    $y_ins->ec2($self->ec2);
    $y_ins->out_columns($self->config->get('instance_column')) if $self->config->get('instance_column');
    $y_ins->out_format($opt->{format} || 'table');

    # action class
    my $ia = Yogafire::Instance::Action->new(
        ec2          => $self->ec2,
        config       => $self->config,
        action_name  => $action_name,
    );

    my $instance = $self->get_self_instance();
    unless($instance) {
        die "Not Found Instance. \n";
    }

    if($self->force) {
        $ia->run([$instance], $opt);
    }

    my $term = Yogafire::Term->new();
    my $yn = $term->ask_yn(
        prompt   => " target self instance, OK? [$action_name] > ",
        default  => 'n',
    );
    return unless $yn;
}

sub get_self_instance {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(5);
    my $response = $ua->get('http://169.254.169.254/latest/meta-data/instance-id');
    return unless $response->is_success;

    my $instance_id = $response->decoded_content;
    my @instances = $self->ec2->describe_instances($instance_id);
    return shift @instances;
}

1;
