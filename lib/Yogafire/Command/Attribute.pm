package Yogafire::Command::Attribute;
use strict;
use warnings;
use Mouse;
extends qw(MouseX::App::Cmd::Command);
has region => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "r",
    documentation => "Specify the region name.",
);
has profile => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    documentation   => "Specifies the profile.",
);
no Mouse;

1;
