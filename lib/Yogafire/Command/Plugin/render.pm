package Yogafire::Command::Plugin::render;
use Mouse;
extends qw(Yogafire::CommandBase);

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

has template => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "x",
    documentation   => "template text. (ex. --template='\"[% dnsName %]\",' )",
);

no Mouse;

use Yogafire::Instance;

sub abstract {'Render Tool'}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    $self->usage_error('<template> option is required.')
         unless $opt->{template};
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $cmd = shift @$args;

    my $y_ins = Yogafire::Instance->new({ ec2 => $self->ec2 });

    # tags name filter
    my $tagsname = $args->[0];
    $opt->{tagsname} = $tagsname if $tagsname;

    my @instances = $y_ins->search($opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    my $template = $opt->{template};
    for my $instance (@instances) {
        $self->render($instance, $template);
    }
}

sub search_tags {
    my ($self, $tag) = @_;
    if ($tag =~ /^tags_(.*)/) {
        return $1;
    }
    return '';
}

sub search_keys {
    my ($self, $key) = @_;
    my @keys = qw/
        instanceId
        ownerId
        reservationId
        imageId
        instanceState
        groups
        privateIpAddress
        ipAddress
        privateDnsName
        dnsName
        launchTime
        current_status
        tags
    /;
    for (@keys) {
        return $_ if $_ eq $key;
    }
    return '';
}

sub render {
    my ($self, $instance, $text) = @_;

    my $tag_start = quotemeta '[% ';
    my $tag_end   = quotemeta ' %]';

    my $proc;
    my @chunk;
    for my $token (split /($tag_start | $tag_end)/x, $text) {
        next if $token eq '';

        if ($proc && $token =~ /^$tag_end$/) {
            my $var = pop @chunk;
            my $key = $self->search_keys($var);
            if($key) {
                # hit key
                push @chunk, $instance->{data}->{$key}||'';
            } else {
                # hit tag?
                my $tag = $self->search_tags($var);
                push @chunk, $instance->tags->{$tag}||'';
            }
            $proc = 0;
        } elsif ($token =~ /^$tag_start$/) {
            $proc = 1;
        } else {
            push @chunk, $token;
        }
    }

    my $str = join('', @chunk);
    $str =~ s/\\n/\n/;

    print $str;
}

1;
