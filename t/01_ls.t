use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;
use Test::Mock::Guard qw(mock_guard);

use lib 't/lib';
use Test::Mock::Set::Instance;

use Yogafire;

use t::Util;
t::Util::set_env();
test_app(Yogafire => [ qw(config --init --noconfirm) ]);

my $guard = mock_guard(
    'VM::EC2' => {
        'describe_instances' => sub { Test::Mock::Set::Instance::mocks() },
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
