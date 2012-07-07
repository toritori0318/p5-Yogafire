use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;
use Test::Mock::Guard qw(mock_guard);
use Test::MockObject;

use lib 't/lib';
use MockInstance;

use Yogafire;

use t::Util;
t::Util::set_env();
test_app(Yogafire => [ qw(config --init --noconfirm) ]);

my $guard = mock_guard(
    'VM::EC2' => {
        'describe_instances' => sub {
            my $mock1 = MockInstance::create(
                {
                    instanceId         => 'ins1',
                    tags_name          => 'hoge',
                    state              => 'running',
                    ipAddress          => '59.100.100.1',
                    privateIpAddress   => '176.0.0.1',
                    dnsName            => 'hogehoge.com',
                }
            );
            my $mock2 = MockInstance::create(
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
    }
);

{
    my $result = test_app(Yogafire => [ qw(ls) ]);
    like($result->stdout, qr/running/,   'printed what we running');
    #unlike($result->stdout, qr/stopped/, 'not printed what we stopped');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}

done_testing;
