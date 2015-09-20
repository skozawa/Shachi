package Shachi::Web::Resource;
use strict;
use warnings;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata;
use Shachi::Service::FacetSearch;
use Shachi::Service::Resource::Metadata;

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

sub facet {
    my ($class, $c) = @_;

    my $facet_metadata_list = Shachi::Service::FacetSearch->facet_metadata_list(
        db => $c->db,
    );

    return $c->html('facet.html', {
        facet_metadata_list => $facet_metadata_list,
    });
}

sub statistics {
    my ($class, $c) = @_;

    my $target = $c->req->parameters->{target};
    my $metadata_list = Shachi::Service::Metadata->find_by_input_types(
        db => $c->db, input_types => [INPUT_TYPE_SELECT, INPUT_TYPE_SELECTONLY],
    );
    return $c->html('statistics.html', { metadata_list => $metadata_list }) unless $target;

    my $metadata = Shachi::Service::Metadata->find_by_name(db => $c->db, name => $target);
    return $c->throw_not_found unless $metadata->allow_statistics;

    my $statistics = Shachi::Service::Resource::Metadata->statistics_by_year(
        db => $c->db, metadata => $metadata,
    );
    $c->html('statistics.html', {
        metadata_list => $metadata_list,
        metadata   => $metadata,
        statistics => $statistics,
    });
}

1;
