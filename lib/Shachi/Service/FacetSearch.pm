package Shachi::Service::FacetSearch;
use strict;
use warnings;
use Smart::Args;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;
use Shachi::Service::Resource;

sub facet_metadata_list {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    my $facet_names = FACET_METADATA_NAMES;
    my $facet_metadata_list = Shachi::Service::Metadata->find_by_names(
        db => $db, names => $facet_names,
        args => { order_by_names => 1 },
    );

    $class->embed_metadata_value_with_count(
        db => $db, metadata_list => $facet_metadata_list,
    );
    $class->embed_no_metadata_resource_count(
        db => $db, metadata_list => $facet_metadata_list,
    );

    return $facet_metadata_list;
}

sub embed_metadata_value_with_count {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $metadata_list => { isa => 'Shachi::Model::List' };

    my $resource_metadata_counts = $db->shachi->table('resource_metadata')
        ->select(\'COUNT(DISTINCT(resource_id)) as count, metadata_id, value_id')
        ->left_join('resource', { resource_id => 'id' })->search({
            metadata_id => { -in => $metadata_list->map('id')->to_a },
            status      => { '!=' => 'private' },
    })->group_by('metadata_id, value_id')->list;
    my $resource_metadata_by_metadata_and_value = $resource_metadata_counts->hash_by(sub {
        $_->metadata_id . '_' . $_->value_id
    });

    my $values_by_type = Shachi::Service::Metadata::Value->find_by_ids(
        db => $db, ids => $resource_metadata_counts->map('value_id')->to_a,
    )->hash_by('value_type');

    foreach my $metadata ( @$metadata_list ) {
        my @values = $values_by_type->get_all($metadata->value_type);
        my @metadata_values;
        foreach my $value ( @values ) {
            my $resource_metadata = $resource_metadata_by_metadata_and_value->{
                $metadata->id . '_' . $value->id
            } or next;
            $value->resource_count($resource_metadata->{count});
            push @metadata_values, $value;
        }
        $metadata->values([ @metadata_values ]);
    }
}

sub embed_no_metadata_resource_count {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $metadata_list => { isa => 'Shachi::Model::List' };

    my $resource_count = Shachi::Service::Resource->count_not_private(db => $db);

    my $has_metadata_count = $db->shachi->table('resource_metadata')
        ->select(\'COUNT(DISTINCT(resource_id)) as count, metadata_id')
        ->left_join('resource', { resource_id => 'id' })->search({
            metadata_id => { -in => $metadata_list->map('id')->to_a },
            status      => { '!=' => 'private' },
        })->group_by('metadata_id')->list;
    my $count_by_metadata_id = $has_metadata_count->hash_by('metadata_id');

    foreach my $metadata ( @$metadata_list ) {
        my $resource_metadata = $count_by_metadata_id->{$metadata->id};
        my $count = $resource_metadata ? $resource_metadata->{count} || 0 : 0;
        $metadata->no_metadata_resource_count($resource_count - $count);
    }

    return $metadata_list;
}

1;
