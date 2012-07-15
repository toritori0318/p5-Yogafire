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
                    instanceId       => 'ins1',
                    tags_name        => 'hoge',
                    state            => 'running',
                    ipAddress        => '59.100.100.3',
                    privateIpAddress => '176.0.0.1',
                    dnsName          => 'hogehoge.com',
                }
            );
            my $mock2 = MockInstance::create(
                {
                    instanceId       => 'ins2',
                    tags_name        => 'fuga',
                    state            => 'stopped',
                    ipAddress        => '59.100.100.4',
                    privateIpAddress => '176.0.0.2',
                    dnsName          => 'fugafuga.com',
                }
            );
            return ($mock1, $mock2);
        }
    }
);

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
