package Yogafire::Plugin::Command::awsstatus;
use Mouse;
extends qw(Yogafire::Command Yogafire::CommandAttribute);
no Mouse;

use Yogafire::Regions qw/list display_table/;
use LWP::UserAgent qw/get/;
use XML::RSS;
use Yogafire::Regions qw/list/;
use Term::ANSIColor qw/colored/;
my $feed = 'http://status.aws.amazon.com/rss/all.rss';

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
        my $service_status = $self->service_status($_->{title});
        my $service_name   = $self->service_name($_->{guid});
        my $region = $self->region($regions, $_->{guid});
        my $print_str =<<"EOF";
============================== $_->{pubDate} ==================================
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
