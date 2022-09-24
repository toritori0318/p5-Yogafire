package Yogafire::Command::Common::use;
use Mouse;
extends qw(Yogafire::CommandBase Yogafire::Command::Attribute);
no Mouse;

use Yogafire::Declare qw/ec2 config/;

sub abstract {'Use profile'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga use [-?] <profile_name>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $profile = shift @$args if $args;

    if($profile && config->get_profile($profile)) {
        config->write_profile($profile);
        print "\n current profile [$profile]\n";
    } else {
        my @profiles = map { $_ } keys %{config->list_merge_profile};
        my $current_profile = config->current_profile();
        print "\n--------- profiles ---------\n";
        for my $profile (sort @profiles) {
           printf " %s %s\n", ($current_profile eq config->trim_aws_profile($profile)) ? '*' : ' ', $profile;
        }
    }

}

1;
