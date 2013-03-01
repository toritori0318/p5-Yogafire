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
has format => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    documentation   => "specified output format(default:table). (table / plain / json)",
);
has loop => (
    traits          => [qw(Getopt)],
    isa             => "Bool",
    is              => "rw",
    cmd_aliases     => "l",
    documentation   => "Repeat without exit interactive mode.",
);
no Mouse;

use Yogafire::Image;
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

    my $y_image = Yogafire::Image->new();
    $y_image->ec2($self->ec2);
    $y_image->out_columns($self->config->get('image_column')) if $self->config->get('image_column');
    $y_image->out_format($opt->{format} || 'table');

    # name filter
    my $name = $args->[0];
    $opt->{name} = $name if $name;

    my @images = $y_image->search($opt);
    if(scalar @images == 0) {
        die "Not Found Image. \n";
    }

    if($opt->{interactive}) {
        my $ia   = Yogafire::Image::Action->new(ec2 => $self->ec2, config => $self->config);
        my $term = Yogafire::Term->new('Input Number');
        $term->set_completion_word( [ map { $_->name, $_->imageId} @images ] );

        while (1) {
            # display
            $y_image->output();
            # confirm
            my $input = $term->readline('no / name / image_id > ');
            $input =~ s/^ //g;
            $input =~ s/ $//g;
            last if $input =~ /^(q|quit|exit)$/;

            my $target_image = $y_image->find_from_cache({ name => $input });
            $target_image  ||= $y_image->find_from_cache({ id => $input });
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
        $y_image->output();
    }
}

1;
