package Yogafire;
use strict;
use warnings;

our $VERSION = '0.01';

use Mouse;
extends qw(MouseX::App::Cmd);
no Mouse;

use App::Cmd::Command::commands;
no warnings 'redefine';
*App::Cmd::Command::commands::execute  = sub {
  my ($self) = @_;

  local $@;
  eval { print $self->app->_usage_text . "\n" };

  print "Available commands:\n\n";

  my $pritty = sub {
    my (@commands) = @_;
    my @cmd_groups = $self->sort_commands(@commands);

    my $fmt_width = 16; # pretty

    foreach my $cmd_set (@cmd_groups) {
      for my $command (@$cmd_set) {
        my $abstract = $self->app->plugin_for($command)->abstract;
        printf "%${fmt_width}s: %s\n", $command, $abstract;
      }
      print "\n";
    }
  };
  # primary command
  my @primary_commands =
    map { ($_->command_names)[0] }
    grep { $_ !~ /::Plugin::/ }
    $self->app->command_plugins;

  $pritty->(@primary_commands);

  # plugins
  my @plugin_commands =
    map { ($_->command_names)[0] } 
    grep { $_ =~ /::Plugin::/ }
    $self->app->command_plugins;

  $pritty->(@plugin_commands);
};

1;
__END__

=head1 NAME

Yogafire -

=head1 SYNOPSIS

  use Yogafire;

=head1 DESCRIPTION

Yogafire is

=head1 AUTHOR

toritori0318 E<lt>toritori0318@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
