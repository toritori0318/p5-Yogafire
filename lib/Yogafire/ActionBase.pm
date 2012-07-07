package Yogafire::ActionBase;
use strict;
use warnings;

use Mouse;
has 'ec2'    => (is => 'rw', isa => 'VM::EC2');
has 'config' => (is => 'rw', isa => 'Yogafire::Config');
no Mouse;

1;
