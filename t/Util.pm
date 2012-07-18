package t::Util;

use strict;
use warnings;
use File::Temp;

use Test::More;
use App::Cmd::Tester;

sub set_env {
    my $fh = File::Temp->new( CLEANUP => 1);
    $ENV{YOGAFIRE_CONFIG} = $fh->filename;
    $ENV{EC2_OWNER_ID} = '123456789';
    $ENV{AWS_ACCESS_KEY_ID} = 'xxxxxxxxxxxxxxx';
    $ENV{AWS_SECRET_ACCESS_KEY} = 'yyyyyyyyyyyyyyyyy';
}

1;
