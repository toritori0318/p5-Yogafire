use strict;
use warnings;
use Test::More;

use t::Util;
BEGIN {
    t::Util::set_env();
}

use App::Cmd::Tester;
use Test::Mock::Guard qw(mock_guard);

use lib 't/lib';
use Test::Mock::Set::Instance;

use Yogafire;

my $input_value;
# mock
my $guard = mock_guard(
    'VM::EC2' => {
        'describe_instances' => sub { Test::Mock::Set::Instance::mocks() },
    },
    'Net::OpenSSH' => {
        'new'      => sub { shift },
        'capture2' => sub {  },
        'error'    => sub {  },
    },
    'Term::ReadLine' => {
        'readline' => sub { $input_value },
    },
);

# create test config
test_app(Yogafire => [ qw(config --init --noconfirm) ]);

# validation 1
{
    my $result = test_app(Yogafire => [ qw(cmd) ]);
    ok($result->error, 'validation1 errror');
}

# validation 2
{
    my $result = test_app(Yogafire => [ qw(cmd hoge) ]);
    ok($result->error, 'validation2 errror');
}

done_testing;
