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

# create config
my $hosts_file = create_hosts_file();

{
    my $str =<<'EOF';
111.111.111.111 hogehoge
#======== Yogafire Begen ========#
59.100.100.1     hoge
59.100.100.2     fuga
#======== Yogafire End   ========#
EOF

    my $result = test_app(Yogafire => [ 'hosts', "--preview", "--hosts-file=$hosts_file" ]);
    is($result->stdout, $str,   'printed hosts file is success');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}

{
    my $str =<<'EOF';
111.111.111.111 hogehoge
#======== Yogafire Begen ========#
176.0.0.1        hoge
176.0.0.2        fuga
#======== Yogafire End   ========#
EOF

    my $result = test_app(Yogafire => [ 'hosts', "--preview", "--hosts-file=$hosts_file", "--private-ip" ]);
    is($result->stdout, $str,   'private ip printed hosts file is success');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}

use File::Temp 'tempfile';
use File::Copy;
sub create_hosts_file {
    my ($fh, $tmpfile) = tempfile;
    print $fh "111.111.111.111 hogehoge";
    close $fh;
    return $tmpfile;
}

done_testing;
