package Test::Mock::Set::Instance;

use strict;
use warnings;
use Test::Mock::Object::Instance;

sub mocks {
    my $mock1 = Test::Mock::Object::Instance::create(
        {
            instanceId         => 'ins1',
            tags_name          => 'hoge',
            state              => 'running',
            ipAddress          => '59.100.100.1',
            privateIpAddress   => '176.0.0.1',
            dnsName            => 'hogehoge.com',
        }
    );
    my $mock2 = Test::Mock::Object::Instance::create(
        {
            instanceId       => 'ins2',
            tags_name        => 'fuga',
            state            => 'stopped',
            ipAddress        => '59.100.100.2',
            privateIpAddress => '176.0.0.2',
            dnsName          => 'fugafuga.com',
        }
    );
    return ($mock1, $mock2);
}

1;
