package Yogafire::Command::Common::use;
use Mouse;

extends qw(Yogafire::CommandBase);

no Mouse;

sub abstract {'Use profile'}

sub usage {
    my ( $self, $opt, $args ) = @_;
    $self->{usage}->{leader_text} = 'yoga use [-?] <profile_name>';
    $self->{usage};
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $ec2  = $self->ec2;
    my $config = $self->config;

    my $profile = shift @$args if $args;

    if($profile) {
        my $section = $config->get_profile($profile);
        if($section) {
            $config->set_profile($profile);
            print " use profile [$profile]\n";
        } else {
            print " Fail! invalid profile [$profile]\n";
        }

    } else {
        my @profiles = map { $_ } keys %{$config->list_profile};
        my $current_profile = $config->current_profile();
        print "--------- profiles ---------\n";
        for my $profile (@profiles) {
           printf " %s %s\n", ($current_profile eq $profile) ? '*' : ' ', $profile;
        }
    }

}

1;
