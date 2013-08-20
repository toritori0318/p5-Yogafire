package Yogafire::Command::Attribute;
use strict;
use warnings;
use Mouse;
extends qw(MouseX::App::Cmd::Command);
has profile => (
    traits          => [qw(Getopt)],
    isa             => "Str",
    is              => "rw",
    documentation   => "Specifies the profile.",
);
no Mouse;

1;
