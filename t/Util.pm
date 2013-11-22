package t::Util;

use strict;
use warnings;
use File::Temp;

use Test::More;
use App::Cmd::Tester;

sub set_env {
    my $fh = File::Temp->new( CLEANUP => 2);
    $DB::single=1;
    $ENV{YOGAFIRE_CONFIG} = $fh->filename;
    $ENV{EC2_OWNER_ID} = '123456789';
    $ENV{AWS_ACCESS_KEY_ID} = 'xxxxxxxxxxxxxxx';
    $ENV{AWS_SECRET_ACCESS_KEY} = 'yyyyyyyyyyyyyyyyy';

    my $yogaconf = <<'EOS';
yoga-test:
  access_key_id: yyyyyyyyyyyyyyyyy
  identity_file: '/path/to/keypem'
  image_column:
    - tags_Name
    - name
    - imageId
    - colorfulImageState
  instance_column:
    - tags_Name
    - instanceId
    - ipAddress
    - privateIpAddress
    - publicIpAddress
    - colorfulInstanceState
  region: ap-northeast-1
  secret_access_key: xxxxxxxxx
  ssh_port: 22
  ssh_user: ec2-user
use_profile: yoga-test
EOS
    print $fh $yogaconf;
    $fh->close;
    return $fh;
}

1;
