package Shachi::Web::Admin::Resource;
use strict;
use warnings;
use Shachi::Service::Resource;

sub find_by_id {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my ($resource, $metadata_list) = Shachi::Service::Resource->find_resource_detail(
        db => $c->db, id => $resource_id, args => { with_value => 1 },
    );
    return $c->throw_not_found unless $resource;

    return $c->html('admin/detail.html', {
        resource => $resource,
        metadata_list => $metadata_list,
    });
}

1;
