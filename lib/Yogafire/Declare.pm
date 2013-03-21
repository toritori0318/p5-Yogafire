package Yogafire::Declare;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/config ec2/;

*config = *Yogafire::CommandBase::config;
*ec2    = *Yogafire::CommandBase::ec2;

1;
