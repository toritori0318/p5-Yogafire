package Yogafire::Command::lsami;
use Mouse;

extends qw(Yogafire::CommandBase);

has interactive => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "i",
    documentation   => "interactive mode.",
);
has name => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "n",
    documentation   => "specified ami name.",
);
has state => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "s",
    documentation   => "specified ami status (available / pending / failed)",
);
has filter => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "f",
    documentation   => "api filter. (ex.--filter='name=value,state=available')",
);
has notable => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "does not display of the table style.",
);
has loop => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "l",
    documentation   => "Repeat without exit interactive mode.",
);
no Mouse;

use Yogafire::Image qw/list display_list display_table/;
use Yogafire::Image::Action;
use Yogafire::Term;

sub abstract {'Image List'}
sub command_names {'ls-ami'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga ls-ami [-?] <name>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    $opt->{owner_id} = $self->ec2->account_id;

    # name filter
    my $name = $args->[0];
    $opt->{name} = $name if $name;

    my @images = list($self->ec2, $opt);
    if(scalar @images == 0) {
        die "Not Found Image. \n";
    }

    if($opt->{interactive}) {
        my $ia   = Yogafire::Image::Action->new(ec2 => $self->ec2, config => $self->config);
        my $term = Yogafire::Term->new('Input Number');
        $term->set_completion_word( [ map { $_->name, $_->imageId} @images ] );

        while (1) {
            # display
            $self->display_images(\@images, $opt);
            # confirm
            my $input = $term->readline('no / name / image_id > ');
            $input =~ s/^ //g;
            $input =~ s/ $//g;
            last if $input =~ /^(q|quit|exit)$/;

            my $target_image = $self->find_image_name(\@images, $input);
            $target_image  ||= $self->find_image_id(\@images, $input);
            $target_image  ||= $images[$input-1] if $input && $input =~ /^\d+$/;
            if (!$target_image) {
                die "Invalid Value. \n";
            }

            # show action
            $ia->confirm($target_image, $opt);

            # for loop
            last unless $opt->{loop};
            my $term = Yogafire::Term->new();
            my $yn = $term->ask_yn(
                prompt   => "\ncontinue OK? > ",
                default  => 'y',
            );
            last unless $yn;
        }
    } else {
        $self->display_images(\@images, $opt);
    }
}

sub display_images {
    my ($self, $images, $opt) = @_;
    my $column_list = $self->config->get('image_column');
    if($opt->{interactive} || !$opt->{notable}) {
        display_table($images, $column_list);
    } else {
        display_list($images, $column_list, $opt->{interactive});
    }
}

sub find_image_name {
    my ($self, $images, $name ) = @_;
    for my $image (@$images) {
        return $image if $image->name eq $name;
    }
}

sub find_image_id {
    my ($self, $images, $image_id ) = @_;
    for my $image (@$images) {
        return $image if $image->imageId eq $image_id;
    }
}

1;
