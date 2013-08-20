package Yogafire::Command::Plugin::render;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

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

has 'template-file' => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    cmd_aliases     => "f",
    documentation   => "specified template file.",
);

has 'template-value' => (
    traits          => [qw(Getopt)],
    isa             => "ArrayRef",
    is              => "rw",
    cmd_aliases     => "V",
    documentation   => "specified template value key(=value). (ex. --template-value='Role=www' --template-value='Env=dev'",
);

no Mouse;

use Yogafire::Instance;
use Yogafire::Util;
use Template;
use JSON;

sub abstract {'Render Tool'}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->validate_args_common($opt, $args );

    $self->usage_error('<template> or <template-file> option is required.')
         unless $opt->{template} || $opt->{'template-file'};
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $cmd = shift @$args;

    my $y_ins = Yogafire::Instance->new();

    # tags name filter
    my $tagsname = $args->[0];
    $opt->{tagsname} = $tagsname if $tagsname;

    my @instances = $y_ins->search($opt);
    if(scalar @instances == 0) {
        die "Not Found Instance. \n";
    }

    # build render string
    my $string;
    my $template_file = $opt->{'template-file'};
    if($opt->{template}) {
        $string = sprintf('[%% FOREACH i IN instances %%]%s[%% END %%]', $opt->{template});
    } elsif($template_file) {
        $string = $self->slurp($template_file);
    }

    my $template_values = Yogafire::Util::key_eq_value_to_hash($opt->{'template-value'});
    my %template_args = (instances => \@instances, %$template_values);
    # create Template object
    my $tt = Template->new({ RELATIVE=>1 });
    $tt->process(\$string, \%template_args)
           || die $tt->error(), "\n"
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

sub slurp {
    my ($self, $file) = @_;
    open my $fh, "<", $file or die "Can't open file [$file].\n";
    my $data = do{ local $/; <$fh>};
    close $fh;
    return $data;
}

1;
