use strict;
use warnings;
use Test::More;

use t::Util;
BEGIN {
    t::Util::set_env();
}

use Yogafire::Instance;

my $m = Yogafire::Instance->new;
{
    my @tests = (
        { str => "59.100.100.1", result => { 'ip-address' => '59.100.100.1' } },
        { str => "10.1.1.128",   result => { 'private-ip-address' => '10.1.1.128' } },
        { str => "ec2-54-1-2-16.ap-northeast-1.compute.amazonaws.com", result => { 'dns-name' => 'ec2-54-1-2-16.ap-northeast-1.compute.amazonaws.com' } },
        { str => "ip-10-150-1-8.ap-northeast-1.compute.internal",      result => { 'private-dns-name' => 'ip-10-150-1-8.ap-northeast-1.compute.internal' } },
        { str => "i-1234abcd",   result => { 'instance-id' => 'i-1234abcd' } },
        { str => "i-12",         result => { 'tag:Name' => 'i-12' } },
        { str => "i-1234abcdte", result => { 'tag:Name' => 'i-1234abcdte' } },
        { str => "eragaeaw",     result => { 'tag:Name' => 'eragaeaw' } },
        { str => "www*",         result => { 'tag:Name' => 'www*' } },
    );

    # get_filter_from_id
    for my $t (@tests) {
        my %result = $m->get_filter_from_host($t->{str});
        is_deeply(\%result, $t->{result})
    }
}

done_testing;
