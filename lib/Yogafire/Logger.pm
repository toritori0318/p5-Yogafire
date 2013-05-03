package Yogafire::Logger;
use strict;
use warnings;
use Log::Minimal;
use base 'Exporter';
our @EXPORT = qw/yinfo ywarn ycrit/;

$Log::Minimal::COLOR = 1;
$Log::Minimal::PRINT = sub {
    my ( $time, $type, $message, $trace,$raw_message) = @_;
    warn " # $time [$type] $message\n";
};

sub _builder {
    my (%data) = @_;
    my $resource = delete $data{resource};
    my @rowheader;
    if(ref $resource eq 'VM::EC2::Instance') {
        push @rowheader, $resource->instanceId;
        push @rowheader, ($resource->tags->{Name}) ? "(".$resource->tags->{Name}.")" : "";
        push @rowheader, $resource->ipAddress if $resource->ipAddress;
    } elsif(ref $resource eq 'VM::EC2::Image') {
        push @rowheader, $resource->imageId;
        push @rowheader, ($resource->tags->{Name}) ? "(".$resource->tags->{Name}.")" : "";
    } else {
        push @rowheader, 'undefined type?';
    }
    my $message = delete $data{message} || '';
    return ( join(' ', @rowheader), $message )
}
sub yinfo {
    my (%data) = @_;
    my ($rowheader, $message) = _builder(%data);
    infoff('[%s] %s', $rowheader, $message);
}

sub ywarn {
    my (%data) = @_;
    my ($rowheader, $message) = _builder(%data);
    warnff('[%s] %s', $rowheader, $message);
}

sub ycrit {
    my (%data) = @_;
    my ($rowheader, $message) = _builder(%data);
    critff('[%s] %s', $rowheader, $message);
}

1;
