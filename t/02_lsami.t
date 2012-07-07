use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;
use Test::Mock::Guard qw(mock_guard);
use Test::MockObject;

use lib 't/lib';
use MockImage;

use Yogafire;

use t::Util;
t::Util::set_env();
test_app(Yogafire => [ qw(config --init --noconfirm) ]);

my $guard = mock_guard(
    'VM::EC2' => {
        'describe_images' => sub {
            my $mock1 = MockImage::create(
                {
                    name       => 'wan',
                    imageId    => 'img1',
                    imageState => 'available',
                }
            );
            my $mock2 = MockImage::create(
                {
                    name       => 'nyan',
                    imageId    => 'img2',
                    imageState => 'available',
                }
            );
            return ($mock1, $mock2);
        }
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
