package Yogafire::Plugin::Command::awsstatus;
use Mouse;
extends qw(Yogafire::Command Yogafire::CommandAttribute);
has from => (
    traits        => [qw(Getopt)],
    isa           => "Int",
    is            => "rw",
    cmd_aliases   => "f",
    documentation => "specify the from-ymd of feed (format: yyyymmdd )",
);
has to => (
    traits        => [qw(Getopt)],
    isa           => "Int",
    is            => "rw",
    cmd_aliases   => "t",
    documentation => "specify the to-ymd of feed (format: yyyymmdd )",
);
no Mouse;

use Yogafire::Regions qw/list display_table/;
use Yogafire::Regions qw/list/;

use LWP::UserAgent qw/get/;
use XML::RSS;
use DateTime::Format::Strptime;
use Term::ANSIColor qw/colored/;

my $feed = 'http://status.aws.amazon.com/rss/all.rss';
my $time_zone = 'Asia/Tokyo';
my $rss_parser = DateTime::Format::Strptime->new(
    time_zone => $time_zone,
    pattern   =>'%a, %d %b %Y %H:%M:%S %Z',
    on_error  => 'croak',
);
my $args_parser = DateTime::Format::Strptime->new(
    time_zone => $time_zone,
    pattern   =>'%Y%m%d',
    on_error  => 'croak',
);


sub abstract {'Show AWS Status'}
sub command_names {'aws-status'}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $cmd = shift @$args;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->get($feed);

    unless ($response->is_success) {
        die $response->status_line;
    }

    my $regions = list();
    my $rss = XML::RSS->new;
    $rss->parse($response->content);
    for (@{$rss->{items}}) {
        my $rss_dt  = $rss_parser->parse_datetime($_->{pubDate});
        my $from_dt = ($opt->{from}) ? $args_parser->parse_datetime($opt->{from}) : undef;
        my $to_dt   = ($opt->{to})   ? $args_parser->parse_datetime($opt->{to}) : undef;
        $to_dt->add(seconds => (60*60*24)-1);

        next if $from_dt && $rss_dt < $from_dt;
        next if $to_dt   && $rss_dt > $to_dt;

        my $service_status = $self->service_status($_->{title});
        my $service_name   = $self->service_name($_->{guid});
        my $region = $self->region($regions, $_->{guid});
        my $print_str =<<"EOF";
============================== $rss_dt ==================================
     service : $service_name
       level : $service_status
      region : $region
       title : $_->{title}
         url : $_->{guid}

EOF
        print $print_str;
    }

}

sub service_status {
    my ($self, $text) = @_;
    if($text =~ /Service is operating normally/) {
        return colored('Normal', 'green');
    } elsif($text =~ /Informational message/) {
        return colored('Info', 'green');
    } elsif($text =~ /Performance issues/) {
        return colored('Warning', 'yellow');
    } elsif($text =~ /Service disruption/) {
        return colored('Error', 'red');
    }
    return 'Unknown';
}

sub region {
    my ($self, $regions, $text) = @_;
    for (@$regions) {
        if($text =~ /$_->{id}/) {
            return $_->{name};
        }
    }
    return 'ALL';
}

sub service_name {
    my ($self,$text) = @_;
    if($text =~ m|/#(\w+)-|) {
        return uc($1);
    }
    return 'Unknown';
}

1;
