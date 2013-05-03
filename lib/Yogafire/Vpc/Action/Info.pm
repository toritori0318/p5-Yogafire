package Yogafire::Vpc::Action::Info;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'info');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/available pending/],
    },
);
no Mouse;

sub proc {
    my ($self, $vpc, $opt) = @_;

    my $print_header = sub {
        my ($header, $dmt, $block) = @_;
        printf("%s%s %s\n", ' 'x$block, $dmt, $header);
        printf("%s%s\n", ' 'x$block, ${dmt}x48);
    };
    my $print = sub {
        my ($col, $value, $block) = @_;
        $block ||= 1;
        $block += 2;
        $value ||= '';
        printf "%s%-16s: %s\n", ' 'x$block, $col, $value;
    };

    $print_header->('Vpc Info', "*", 1);
    my $tags_name = ($vpc->tags && $vpc->tags->{Name}) ? $vpc->tags->{Name} : 'none';
    $print->('vpcId'           , sprintf("%s(%s)", $vpc->vpcId, $tags_name));
    $print->('cidrBlock'       , $vpc->cidrBlock);
    $print->('dhcpOptionsId'   , $vpc->dhcpOptionsId);
    $print->('instanceTenancy' , $vpc->instanceTenancy);
    print "\n";

    my @vpc_route_tables = $vpc->route_tables;

    # Subnet
    my @p_subnets;
    for my $subnet (@{[$vpc->subnets]}) {
        my $block = 5;
        my $tags_name = ($subnet->tags && $subnet->tags->{Name}) ? $subnet->tags->{Name} : 'none';
        $print_header->('Subnet Info', "+", $block);
        $print->('subnetId'         , sprintf("%s(%s)", $subnet->subnetId, $tags_name), $block);
        $print->('state'            , $subnet->state, $block);
        $print->('cidrBlock'        , $subnet->cidrBlock, $block);
        $print->('availabilityZone' , $subnet->availabilityZone, $block);
        $print->('availableIpCount' , $subnet->availableIpAddressCount, $block);
        # route table
        my @route_tables = grep { $_->subnetId && $_->subnetId eq $subnet->subnetId } map { @{[$_->associations]} } @vpc_route_tables;
        my $route_table = shift @route_tables || '';
        my $target_route_table;
        if($route_table) {
            $target_route_table = $self->info_route_table(\@vpc_route_tables, $route_table->routeTableId);
        } else {
            $target_route_table = $self->info_main_route_table(\@vpc_route_tables);
        }
        $print->('routeTableId', $target_route_table, $block);
        print "\n";
    }

    # Route Table
    for my $rt (@vpc_route_tables) {
        my $block = 5;
        my $tags_name = ($rt->tags && $rt->tags->{Name}) ? $rt->tags->{Name} : 'none';
        $print_header->('Route Table Info', "=", $block);
        $print->('routeTableId', sprintf("%s(%s)", $rt->routeTableId, $tags_name), $block);
        print "\n";
        for my $a (@{[$rt->associations]}) {
            my $block = 9;
            my $tags_name = ($rt->tags && $rt->tags->{Name}) ? $rt->tags->{Name} : 'none';
            $print_header->('Route Association Info', "-", $block);
            $print->('main'          , ($a->main) ? 'True':'False', $block);
            $print->('routeTableId'  , sprintf("%s(%s)", $rt->routeTableId, $tags_name), $block);
            $print->('AssociationId' , $a->routeTableAssociationId, $block);
            $print->('subnetId'      , $a->subnetId, $block);
            print "\n";
        }
    }

    # Internet Gateway
    for my $gw (@{[$vpc->internet_gateways]}) {
        my $block = 5;
        my $tags_name = ($gw->tags && $gw->tags->{Name}) ? $gw->tags->{Name} : 'none';
        $print_header->('Internet Gateway Info', "#", $block);
        $print->('internetGatewayId', sprintf("%s(%s)", $gw->internetGatewayId, $tags_name), $block);
        print "\n";
    }

};

sub info_route_table {
    my ($self, $routes, $route_table_id) = @_;
    my @route_tables = grep { $_->routeTableId eq $route_table_id } @$routes;
    return shift @route_tables;
}

sub info_main_route_table {
    my ($self, $routes) = @_;
    my @route_tables = grep { $_->main } @$routes;
    return shift @route_tables;
}

1;
