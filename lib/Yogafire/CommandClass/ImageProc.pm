package Yogafire::CommandClass::ImageProc;
use Mouse;
has opt         => ( is  => "rw" );
has action      => ( is  => "rw" );
has force       => ( is  => "rw" );
has interactive => ( is  => "rw" );
has loop        => ( is  => "rw" );
has yogafire    => ( is  => "rw" );
no Mouse;

use LWP::UserAgent;
use Yogafire::Image;
use Yogafire::Image::Action;
use Yogafire::Term;
use Yogafire::Declare qw/ec2 config/;

sub action_process {
    my ($self) = @_;
    my $action_name = $self->action;
    my $opt         = $self->opt || {};

    my $y_image = Yogafire::Image->new();
    $y_image->out_columns(config->get('image_column')) if config->get('image_column');
    $y_image->out_format($opt->{format} || 'table');

    # action class
    my $ia = Yogafire::Image::Action->new(
        action_name  => $action_name,
    );

    my @images = $y_image->search($opt);
    if(scalar @images == 0) {
        die "Not Found Image. \n";
    } elsif(scalar @images == 1 && $ia->action_class) {
        $ia->procs(\@images, $opt);
        return;
    }

    # force
    if($self->force && $ia->action_class) {
        return $ia->procs(\@images, $opt);
    }

    my $term = Yogafire::Term->new();
    $term->set_completion_word([map {$_->name} @images]);

    while (1) {
        # display
        $y_image->output();
        return unless $self->interactive;

        # confirm
        my $yogafire = ($self->{yogafire}) ? '/ ("yogafire" is all target)': '';
        my $input = $term->readline("no / name / image_id ${yogafire}> ");
        $input =~ s/^ //g;
        $input =~ s/ $//g;
        last if $input =~ /^(q|quit|exit)$/;
        next unless $input;

        my $target_image = $y_image->find_from_cache({ name => qr/^$input$/ });
        $target_image  ||= $y_image->find_from_cache({ id   => qr/^$input$/ });
        $target_image  ||= $y_image->cache->[$input-1] if $input && $input =~ /^\d+$/;
        if (!$target_image) {
            my @target_images = $y_image->search_from_cache({ name => qr/$input/ });
            if(scalar @target_images == 0) {
                if($self->{yogafire} && $input eq 'yogafire') {
                    # all target
                    $ia->procs($y_image->cache, $opt);
                    last;
                } else {
                    print "Invalid Value. \n";
                }
            } elsif(scalar @target_images == 1) {
                # run action
                $ia->procs($target_images[0], $opt);
            } else {
                $y_image->cache(\@target_images);
            }
            next;
        }

        # run action
        $ia->procs($target_image, $opt);

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
