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

# run cmd
{
    my $result = test_app(Yogafire => [ qw(cmd '*' 'ls' --dry-run) ]);
    my $str =<<'EOF';
# Connected to ec2-user@59.100.100.1(hoge)
# Connected to ec2-user@59.100.100.2(fuga)
EOF
    chomp($str);
    $str = quotemeta($str);
    like($result->stdout, qr/$str/, 'printed what we list');
    is($result->error, undef, '');
}

# run cmd
{
    $input_value = 'secret';
    my $result = test_app(Yogafire => [ qw(cmd '*' 'ls' -s -P) ]);
    my $str =<<'EOF';
# Connected to ec2-user@59.100.100.1(hoge)
# Connected to ec2-user@59.100.100.2(fuga)
EOF
    chomp($str);
    $str = quotemeta($str);
    like($result->stdout, qr/$str/, 'printed what we list');
    is($result->error, undef, '');
}

done_testing;
