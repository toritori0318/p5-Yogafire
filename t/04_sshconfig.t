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

test_app(Yogafire => [ qw(config --init --noconfirm) ]);

my $guard = mock_guard(
    'VM::EC2' => {
        'describe_instances' => sub { Test::Mock::Set::Instance::mocks() },
    }
);

{
# create config
my $sshconfig_file = create_sshconfig_file();
{
    my $str =<<'EOF';
Host fugafuga
    HostName     wannyan.com
    IdentityFile 
    User         ec2-user
    Port         22

#======== Yogafire Begen ========#
Host hoge
    HostName     hogehoge.com
    IdentityFile 
    User         ec2-user
    Port         22

Host fuga
    HostName     fugafuga.com
    IdentityFile 
    User         ec2-user
    Port         22
#======== Yogafire End   ========#
EOF

    my $result = test_app(Yogafire => [ 'sshconfig', "--preview", "--sshconfig-file=$sshconfig_file" ]);
    is($result->stdout, $str,   'printed sshconfig file is success');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}
}


{
# create config
my $sshconfig_file = create_sshconfig_file();
{
    my $str =<<'EOF';
Host fugafuga
    HostName     wannyan.com
    IdentityFile 
    User         ec2-user
    Port         22

#======== Yogafire Begen ========#
Host hoge
    HostName     hogehoge.com
    IdentityFile 
    User         ec2-user
    Port         22

Host fuga
    HostName     fugafuga.com
    IdentityFile 
    User         ec2-user
    Port         22
    ProxyCommand ssh hoge -W %h:%p
#======== Yogafire End   ========#
EOF

    my $result = test_app(Yogafire => [ 'sshconfig', "--proxy=hoge", "--preview", "--sshconfig-file=$sshconfig_file" ]);
    is($result->stdout, $str,   'printed sshconfig file is success');
    is($result->stderr, '', '');
    is($result->error, undef, '');
}
}

use File::Temp 'tempfile';
use File::Copy;
sub create_sshconfig_file {
    my ($fh, $tmpfile) = tempfile;
    print $fh <<'EOF';
Host fugafuga
    HostName     wannyan.com
    IdentityFile 
    User         ec2-user
    Port         22
EOF
    close $fh;
    return $tmpfile;
}

done_testing;
