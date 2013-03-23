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
    'Term::ReadLine' => {
        'readline' => sub { $input_value },
    },
);

# create test config
test_app(Yogafire => [ qw(config --init --noconfirm) ]);

use Term::ANSIColor qw/colored/;
# run cmd
{
    my $running = colored('running', 'green');
    my $stopped = colored('stopped', 'red');
    $input_value = '1';
    my $result = test_app(Yogafire => [ qw(info) ]);
    print $result->stdout;
    print $result->stderr;
    my $str =<<"EOF";
.----+-----------+------------+--------------+------------------+------------+-----------------------.
| no | tags_Name | instanceId | ipAddress    | privateIpAddress | launchTime | colorfulInstanceState |
+----+-----------+------------+--------------+------------------+------------+-----------------------+
|  1 | hoge      | ins1       | 59.100.100.1 | 176.0.0.1        |            | $running               |
|  2 | fuga      | ins2       | 59.100.100.2 | 176.0.0.2        |            | $stopped               |
'----+-----------+------------+--------------+------------------+------------+-----------------------'
EOF
    chomp($str);
    $str = quotemeta($str);
    like($result->stdout, qr/$str/, 'printed what we list');
    like($result->stdout, qr/
================ Instance Info ================
              Name: hoge
    current_status: 
        instanceId: ins1
         ipAddress: 59\.100\.100\.1
  privateIpAddress: 176\.0\.0\.1
           dnsName: hogehoge\.com
/,
    'printed what we info');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}

done_testing;
