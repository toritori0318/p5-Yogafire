package Yogafire::Command::Plugin::awsstatus;
use Mouse;

extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);

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
has region => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "r",
    documentation => "specify the region name.",
);
has service => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "s",
    documentation => "specify the service name.",
);
no Mouse;

use Yogafire::Regions;

use LWP::UserAgent qw/get/;
use XML::RSS;
use DateTime::Format::Strptime;
$DateTime::Format::Strptime::ZONEMAP{PST} = '-0800';
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

    my $y_region = Yogafire::Regions->new();

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->get($feed);

    unless ($response->is_success) {
        die $response->status_line;
    }

    my $rss = XML::RSS->new;
    $rss->parse($response->content);
    for (@{$rss->{items}}) {
        my $rss_dt  = $rss_parser->parse_datetime($_->{pubDate});
        my $from_dt = ($opt->{from}) ? $args_parser->parse_datetime($opt->{from}) : undef;
        my $to_dt   = do {
            my $dt;
            if($opt->{to}) {
                $dt = $args_parser->parse_datetime($opt->{to});
                $dt->add(seconds => (60*60*24)-1);
            }
            $dt;
        };

        my $service_status = $self->service_status($_->{title});
        my $service_name   = $self->service_name($_->{guid});
        my $find_region    = $y_region->find($_->{guid});

        # filter
        next if $from_dt && $rss_dt < $from_dt;
        next if $to_dt   && $rss_dt > $to_dt;
        # region
        next if $opt->{region}  && ( ($opt->{region} ne $find_region->{id}) || (!$find_region->{name}) );
        # service
        next if $opt->{service} && lc($opt->{service}) ne lc($service_name);

        my $region_name = $find_region->{name} || 'ALL';

        my $print_str =<<"EOF";
============================== $rss_dt ==================================
     service : $service_name
       level : $service_status
      region : $region_name
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

sub service_name {
    my ($self,$text) = @_;
    if($text =~ m|/#(\w+)-|) {
        return uc($1);
    }
    return 'Unknown';
}

1;
