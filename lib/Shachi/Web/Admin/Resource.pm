package Shachi::Web::Admin::Resource;
use strict;
use warnings;
use JSON::Types;
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

sub delete {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    Shachi::Service::Resource->delete_by_id(db => $c->db, id => $resource->id);

    $c->json({ success => JSON::Types::bool(1) });
}

sub update_status {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $status = $c->req->param('status') or return $c->throw_bad_request;

    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    Shachi::Service::Resource->update_status(
        db => $c->db, id => $resource_id, status => $status,
    );

    $c->json({ status => $status });
}

sub update_edit_status {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $edit_status = $c->req->param('edit_status') or return $c->throw_bad_request;

    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    Shachi::Service::Resource->update_edit_status(
        db => $c->db, id => $resource_id, edit_status => $edit_status,
    );

    $c->json({ edit_status => $edit_status });
}

1;
