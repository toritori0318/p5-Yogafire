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
);

# create test config
test_app(Yogafire => [ qw(config --init --noconfirm) ]);

use Term::ANSIColor qw/colored/;
# run cmd
{
    my $result = test_app(Yogafire => [ "render", "--template=[% i.ipAddress %],", "--state=running" ]);
    my $str ="59.100.100.1,59.100.100.2,";
    like($result->stdout, qr/$str/, 'printed what we list');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}

done_testing;
