package Yogafire;
use strict;
use warnings;

our $VERSION = '0.05';

use Mouse;
extends qw(MouseX::App::Cmd);
no Mouse;

use Yogafire::CommandBase;
use Yogafire::Declare;

my @command_class = qw/
    Common
    Instance
    Image
    SpotInstance
    Vpc
    Plugin
/;
sub plugin_search_path {
    [ map { 'Yogafire::Command::' . $_ } @command_class ];
}

use App::Cmd::Command::commands;
no warnings 'redefine';
*App::Cmd::Command::commands::execute  = sub {
  my ($self) = @_;

  local $@;
  eval { print $self->app->_usage_text . "\n" };

  my $pritty = sub {
    my (@commands) = @_;
    my @cmd_groups = $self->sort_commands(@commands);

    my $fmt_width = 22; # pretty

    foreach my $cmd_set (@cmd_groups) {
      for my $command (@$cmd_set) {
        my $abstract = $self->app->plugin_for($command)->abstract;
        printf "%${fmt_width}s: %s\n", $command, $abstract;
      }
      print "\n";
    }
  };

  my $filter_commonds = sub {
      my ($filter) = @_;
      return
          map { ($_->command_names)[0] }
             grep { $_ =~ /$filter/ }
                $self->app->command_plugins;
  };
  print "\n";
  # common command
  for my $cmd (@command_class) {
      my @commands = $filter_commonds->("::${cmd}::");
      print "$cmd commands:";
      $pritty->(@commands);
  }
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
