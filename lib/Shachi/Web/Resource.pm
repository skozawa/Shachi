package Shachi::Web::Resource;
use strict;
use warnings;
use Shachi::Service::Resource;

sub find_by_id {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my ($resource, $metadata_list) = Shachi::Service::Resource->find_resource_detail(
        db => $c->db, id => $resource_id,
    );
    return $c->throw_not_found unless $resource;

    return $c->html('detail.html', {
        resource => $resource,
        metadata_list => $metadata_list,
    });
}

sub list {
    my ($class, $c) = @_;
    my $resources = Shachi::Service::Resource->search_all(db => $c->db);
    Shachi::Service::Resource->embed_title(db => $c->db, resources => $resources);
    return $c->html('list.html', { resources => $resources });
}

1;
