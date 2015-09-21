package Shachi::Service::FacetSearch;
use strict;
use warnings;
use Smart::Args;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;
use Shachi::Service::Resource;

sub search {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $query => { isa => 'Shachi::FacetSearchQuery' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $args  => { isa => 'HashRef', default => {} };

    $query->current_values(Shachi::Service::Metadata::Value->find_by_ids(
        db => $db, ids => $query->all_value_ids
    ));

    my $resource_ids = [];
    my $metadata_by_name = $metadata_list->hash_by('name');
    my $no_info_metadata_ids = [ map {
        my $metadata = $metadata_by_name->{$_};
        $metadata ? $metadata->id : ()
    } @{$query->no_info_metadata_names} ];
    if( @$no_info_metadata_ids ) {
        $resource_ids = $db->shachi->table('resource')->select('id')
            ->left_join('resource_metadata', {
                'resource_metadata.metadata_id' => {
                    -in => $no_info_metadata_ids,
                },
                id => 'resource_id',
            })->search({
                status => { '!=' => 'private' },
                metadata_id => { '!=' => undef },
            })->list->map('id')->to_a;
    }

    my $metadata_conditions = [];
    foreach my $metadata ( @$metadata_list ) {
        my $value_ids = $query->valid_value_ids($metadata->name);
        next unless @$value_ids;
        push @$metadata_conditions, { -and => {
            metadata_id => $metadata->id,
            value_id    => $_,
        } } for @$value_ids;
    }

    my $searched_resource_ids = $db->shachi->table('resource_metadata')
        ->select(\'resource_id')
        ->left_join('resource', { resource_id => 'id' })->search({
            status => { '!=' => 'private' },
            @$metadata_conditions ? (-or => $metadata_conditions) : (),
            @$resource_ids ? (resource_id => { -in => $resource_ids }) : (),
        })->group_by('resource_id')
          ->having('COUNT(*) >= ' . (scalar @$metadata_conditions))
          ->list->map('resource_id')->to_a;

    my $resources = $db->shachi->table('resource')->search({
        status => { '!=' => 'private' },
        id     => { -in => $searched_resource_ids },
    })->order_by('id asc')
      ->offset($args->{offset} || 0)->limit($args->{limit} || 20)
      ->list;

    $class->embed_metadata_counts(
        db => $db, metadata_list => $metadata_list,
        resource_ids => $searched_resource_ids,
    );

    return $resources;
}

sub embed_metadata_counts {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $resource_ids  => { optional => 1 };

    $class->embed_metadata_value_with_count(
        db => $db, metadata_list => $metadata_list, resource_ids => $resource_ids,
    );
    $class->embed_no_metadata_resource_count(
        db => $db, metadata_list => $metadata_list, resource_ids => $resource_ids,
    );
}

sub embed_metadata_value_with_count {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $resource_ids  => { optional => 1 };

    my $resource_metadata_counts = $db->shachi->table('resource_metadata')
        ->select(\'COUNT(DISTINCT(resource_id)) as count, metadata_id, value_id')
        ->left_join('resource', { resource_id => 'id' })->search({
            metadata_id => { -in => $metadata_list->map('id')->to_a },
            status      => { '!=' => 'private' },
            $resource_ids ? (resource_id => { -in => $resource_ids }) : (),
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
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $resource_ids  => { optional => 1 };

    my $resource_count = $resource_ids ? scalar @$resource_ids :
        Shachi::Service::Resource->count_not_private(db => $db);

    my $has_metadata_count = $db->shachi->table('resource_metadata')
        ->select(\'COUNT(DISTINCT(resource_id)) as count, metadata_id')
        ->left_join('resource', { resource_id => 'id' })->search({
            metadata_id => { -in => $metadata_list->map('id')->to_a },
            status      => { '!=' => 'private' },
            $resource_ids ? (resource_id => { -in => $resource_ids }) : (),
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
