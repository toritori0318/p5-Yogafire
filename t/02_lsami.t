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
use Test::Mock::Set::Image;

use Yogafire;


test_app(Yogafire => [ qw(config --init --noconfirm) ]);

my $guard = mock_guard(
    'VM::EC2' => {
        'describe_images' => sub { Test::Mock::Set::Image::mocks() },
        'account_id' => sub {
            return 'dummyowner';
        },
    }
);

{
    my $result = test_app(Yogafire => [ qw(ls-ami) ]);
    like($result->stdout, qr/available/,   'printed what we available');
    #unlike($result->stdout, qr/stopped/, 'not printed what we stopped');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}

done_testing;
