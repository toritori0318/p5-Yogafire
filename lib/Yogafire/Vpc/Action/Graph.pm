package Yogafire::Vpc::Action::Graph;
use strict;
use warnings;

use Mouse;
extends 'Yogafire::ActionBase';

has 'name'  => (is => 'rw', isa => 'Str', default => 'graph');
has 'state' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {
        [qw/available pending/],
    },
);
no Mouse;

use List::Util qw/max/;
use Graph::Easy;

sub proc {
    my ($self, $vpc, $opt) = @_;

    my $format                = $opt->{format} || 'ascii';
    my $bool_route_table      = $opt->{'route-table'};
    my $bool_internet_gateway = $opt->{'internet-gateway'};
    my $bool_detail           = $opt->{'detail'};

    my $g = Graph::Easy->new();
    # test...
    $g->set_attributes( 'node', { color => 'red' } );

    my $vpc_id = $vpc->vpcId;
    my @vpc_route_tables = $vpc->route_tables;
    # vpc group
    my ($group) = $g->add_group($self->make_vpc($vpc));
    # subnet
    my @p_subnets;
    for my $subnet (@{[$vpc->subnets]}) {
        my $node_subnet = $g->add_node($self->make_subnet($subnet, $bool_detail));
        $group->add_node($node_subnet);

        next unless $bool_route_table;

        # route table
        my @route_tables = grep { $_->subnetId && $_->subnetId eq $subnet->subnetId } map { @{[$_->associations]} } @vpc_route_tables;
        my $route_table  = shift @route_tables;
        my $target_route_table;
        if($route_table) {
            $target_route_table = $self->search_route_table(\@vpc_route_tables, $route_table->routeTableId);
        } else {
            $target_route_table = $self->search_main_route_table(\@vpc_route_tables);
        }

        my $node_route_table = $g->add_node($self->make_route_table($target_route_table, $bool_detail));
        $group->add_node($node_route_table);
        $g->add_edge_once($node_subnet, $node_route_table);

        # connect internet gateway
        my @subnet_gws  = grep { $_->gatewayId && $_->gatewayId ne 'local' } $target_route_table->routes;
        my @connect_gws = @{[$vpc->internet_gateways]};
        for my $sgw (@subnet_gws) {
            for my $igw (@connect_gws) {
                if($sgw->gatewayId eq $igw->internetGatewayId) {
                    my $node_internet_gateway = $g->add_node($self->make_internet_gateway($igw, $vpc_id, $bool_detail));
                    $group->add_node($node_internet_gateway);
                    $g->add_edge_once($node_route_table, $node_internet_gateway);
                    next;
                }
            }
        }
    }

    # not connect gateway
    for my $gw (@{[$vpc->internet_gateways]}) {
        next unless $bool_internet_gateway;

        my $node_internet_gateway = $g->add_node($self->make_internet_gateway($gw, $vpc_id, $bool_detail));
        $group->add_node($node_internet_gateway);
    }

    # output
    if($format eq 'boxart') {
        print $g->as_boxart();
    } else {
        print $g->as_ascii();
    }
};

sub search_route_table {
    my ($self, $routes, $route_table_id) = @_;
    my @route_tables = grep { $_->routeTableId eq $route_table_id } @$routes;
    return shift @route_tables;
}

sub search_main_route_table {
    my ($self, $routes) = @_;
    my @route_tables = grep { $_->main } @$routes;
    return shift @route_tables;
}

sub make_vpc {
    my ($self, $resource) = @_;
    my $tags_name = ($resource->tags && $resource->tags->{Name}) ? $resource->tags->{Name} : 'none';
    my $str = sprintf("%s(%s) %s", $resource->vpcId, $tags_name, $resource->cidrBlock);
    return $str;
}

sub make_subnet {
    my ($self, $resource, $detail) = @_;
    my $tags_name = ($resource->tags && $resource->tags->{Name}) ? $resource->tags->{Name} : 'none';
    my $category  = 'Subnet';
    my $header    = sprintf("%s(%s)", $resource->subnetId, $tags_name);
    my @bodies    = ($resource->cidrBlock, $resource->availabilityZone, $resource->state);
    my $max_width = max( map { length($_) } ($header, @bodies) );
    my $separater = '-' x $max_width;

    my @lines     = ($category, $separater, $header);
    if($detail) {
        push @lines, ($separater, @bodies);
    }
    return join('\n', @lines);
}

sub make_route_table {
    my ($self, $resource, $detail) = @_;
    my $tags_name = ($resource->tags && $resource->tags->{Name}) ? $resource->tags->{Name} : 'none';
    my $category  = sprintf("Route Table %s", ($resource->main ? "(main)" : ""));
    my $header    = sprintf("%s(%s)", $resource->routeTableId, $tags_name);
    my @bodies;

    for my $r (@{[$resource->routes]}) {
        if($r->gatewayId) {
            push @bodies, sprintf("gateway:%s:%s", $r->gatewayId, $r->destinationCidrBlock);
        }
        elsif($r->instanceId) {
            push @bodies, sprintf("instance:%s:%s", $r->instanceId, $r->destinationCidrBlock);
        }
        elsif($r->networkInterfaceId) {
            push @bodies, sprintf("nic:%s:%s", $r->networkInterfaceId, $r->destinationCidrBlock);
        }
    }

    my $max_width = max( map { length($_) } ($header, @bodies) );
    my $separater = '-' x $max_width;

    my @lines     = ($category, $separater, $header);
    if($detail) {
        push @lines, ($separater, @bodies);
    }
    return join('\n', @lines);
}

sub make_internet_gateway {
    my ($self, $resource, $vpc_id, $detail) = @_;
    my $tags_name = ($resource->tags && $resource->tags->{Name}) ? $resource->tags->{Name} : 'none';
    my $category = 'Internet Gateway';
    my $header   = sprintf("%s(%s)", $resource->internetGatewayId, $tags_name);

    my $attachment = shift @{[grep { $_->vpcId eq $vpc_id} $resource->attachments]};
    my @bodies  = ($attachment->state);

    my $max_width = max( map { length($_) } ($header, @bodies) );
    my $separater = '-' x $max_width;

    my @lines     = ($category, $separater, $header);
    if($detail) {
        push @lines, ($separater, @bodies);
    }
    return join('\n', @lines);
}

1;
