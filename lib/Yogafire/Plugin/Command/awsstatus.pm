package Yogafire::Plugin::Command::awsstatus;
use Mouse;
extends qw(Yogafire::Command Yogafire::CommandAttribute);
has all => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "rw",
    documentation => "Show all",
);

no Mouse;

use Yogafire::Regions qw/list display_table/;
use LWP::UserAgent qw/get/;
use XML::RSS;
use AWSKnife::Regions qw/list/;
my $feed = 'http://status.aws.amazon.com/rss/all.rss';

sub abstract {'Show AWS Status'}

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

    my $rss = XML::RSS->new;
    $rss->parse($response->content);
    for (@{$rss->{items}}) {
#   warn Dumper $_;
        warn '-'x32;
        warn $_->{title};
        warn $_->{description};
        warn $_->{guid};
        warn $_->{pubDate};
        warn service_status($_->{title});
    }

}

sub service_status {
    my ($text) = @_;
    if($text =~ /Service is operating normally/) {
        return 'normal';
    } elsif($text =~ /Informational message/) {
        return 'info';
    } elsif($text =~ /Performance issues/) {
        return 'warn';
    } elsif($text =~ /Service disruption/) {
        return 'error';
    }
}

sub service_name {
    my ($text) = @_;
    if($text =~ /Service is operating normally/) {
        return 'normal';
    } elsif($text =~ /Informational message/) {
        return 'info';
    } elsif($text =~ /Performance issues/) {
        return 'warn';
    } elsif($text =~ /Service disruption/) {
        return 'error';
    }
}

#http://status.aws.amazon.com/#elasticache-sa-east-1_1335850302
sub parse_url {
    my ($url) = @_;
    if($url =~ /#(.*)-(\w+)$/) {
    }
}

1;
