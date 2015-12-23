package Shachi::Web::Resource;
use strict;
use warnings;
use Shachi::FacetSearchQuery;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata;
use Shachi::Service::FacetSearch;
use Shachi::Service::Resource::Metadata;

sub find_by_id {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my ($resource, $metadata_list) = Shachi::Service::Resource->find_resource_detail(
        db => $c->db, id => $resource_id, language => $c->lang,
    );
    return $c->throw_not_found unless $resource;
    return $c->throw_not_found if $c->mode eq 'asia' && !$resource->is_asia_resource;

    return $c->html('detail.html', {
        resource => $resource,
        metadata_list => $metadata_list,
    });
}

sub list {
    my ($class, $c) = @_;
    my $resources = $c->mode eq 'asia'
        ? Shachi::Service::Resource->search_asia_all(db => $c->db)
        : Shachi::Service::Resource->search_all(db => $c->db);
    Shachi::Service::Resource->embed_title(
        db => $c->db, resources => $resources,
        language => $c->lang, args => { fillin_english => 1 },
    );
    return $c->html('list.html', { resources => $resources });
}

sub facet {
    my ($class, $c) = @_;

    my $query = Shachi::FacetSearchQuery->new(params => $c->req->parameters);
    my $facet_metadata_list = Shachi::Service::Metadata->find_by_names(
        db => $c->db, names => FACET_METADATA_NAMES,
        args => { order_by_names => 1 },
    );
    $query->total_count(
        $c->mode eq 'asia' ? Shachi::Service::Resource->count_not_private_asia(db => $c->db)
            : Shachi::Service::Resource->count_not_private(db => $c->db)
    );
    my $resources;
    if ( $query->has_any_query ) {
        $resources = Shachi::Service::FacetSearch->search(
            db => $c->db, query => $query, metadata_list => $facet_metadata_list,
        );
        if ( @$resources ) {
            Shachi::Service::Resource->embed_title(
                db => $c->db, resources => $resources, language => $c->lang,
            );
            Shachi::Service::Resource->embed_description(
                db => $c->db, resources => $resources, language => $c->lang,
            );
        }
    } else {
        Shachi::Service::FacetSearch->embed_metadata_counts(
            db => $c->db, metadata_list => $facet_metadata_list,
        );
    }

    return $c->html('facet.html', {
        query => $query,
        facet_metadata_list => $facet_metadata_list,
        resources => $resources,
    });
}

sub statistics {
    my ($class, $c) = @_;

    my $target = $c->req->parameters->{target};
    my $metadata_list = Shachi::Service::Metadata->find_by_input_types(
        db => $c->db, input_types => [INPUT_TYPE_SELECT, INPUT_TYPE_SELECTONLY, INPUT_TYPE_LANGUAGE],
    );
    return $c->html('statistics.html', { metadata_list => $metadata_list }) unless $target;

    my $metadata = Shachi::Service::Metadata->find_by_name(db => $c->db, name => $target);
    return $c->throw_not_found unless $metadata;
    return $c->throw_bad_request unless $metadata->allow_statistics;

    my $statistics = Shachi::Service::Resource::Metadata->statistics_by_year(
        db => $c->db, metadata => $metadata, mode => $c->mode,
    );
    $c->html('statistics.html', {
        metadata_list => $metadata_list,
        metadata   => $metadata,
        statistics => $statistics,
    });
}

1;
