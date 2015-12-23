package Shachi::Service::FacetSearch;
use strict;
use warnings;
use Smart::Args;
use SQL::Abstract;
use Shachi::Model::Metadata;
use Shachi::Service::Asia;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;
use Shachi::Service::Resource;

sub search {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $query => { isa => 'Shachi::FacetSearchQuery' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $mode  => { isa => 'Str', default => 'default' };

    # Facet検索で指定されてる値を設定
    $query->current_values(Shachi::Service::Metadata::Value->find_by_ids(
        db => $db, ids => $query->all_value_ids
    ));

    my $searched_resource_ids = $class->search_by_metadata(
        db => $db, query => $query, metadata_list => $metadata_list, mode => $mode,
    );
    $searched_resource_ids = $class->search_by_keyword(
        db => $db, query => $query, resource_ids => $searched_resource_ids,
    );

    $query->search_count(scalar @$searched_resource_ids);

    my $resources = $db->shachi->table('resource')->search({
        status => { '!=' => 'private' },
        id     => { -in => $searched_resource_ids },
    })->order_by('id asc')
      ->offset($query->offset)->limit($query->limit)
      ->list;

    $class->embed_metadata_counts(
        db => $db, metadata_list => $metadata_list,
        resource_ids => $searched_resource_ids,
    );

    return $resources;
}

sub search_by_metadata {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $query => { isa => 'Shachi::FacetSearchQuery' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $mode  => { isa => 'Str', default => 'default' };

    my $metadata_conditions = $class->_metadata_conditions(
        query => $query, metadata_list => $metadata_list
    );
    my $no_info_conditions = $class->_no_information_conditions(
        query => $query, metadata_list => $metadata_list
    );

    my $conditions = {};
    $conditions->{'-or'} = $metadata_conditions if @$metadata_conditions;
    $conditions->{'-and'} = [ { status => { '!=' => 'private' } } ];
    push @{$conditions->{'-and'}}, { resource_id => \$no_info_conditions } if $no_info_conditions;
    if ( $mode eq 'asia' ) {
        my $subquery = Shachi::Service::Asia->resource_ids_subquery(db => $db);
        push @{$conditions->{'-and'}}, { resource_id => \$subquery };
    }

    my $resource_ids = $db->shachi->table('resource_metadata')->select('resource_id')
        ->left_join('resource', { resource_id => 'id' })->search($conditions)
        ->group_by('resource_id')->having('COUNT(*) >= ' . (scalar @$metadata_conditions))
        ->list->map('resource_id')->to_a;

    return $resource_ids;
}

sub _metadata_conditions {
    args my $class => 'ClassName',
         my $query => { isa => 'Shachi::FacetSearchQuery' },
         my $metadata_list => { isa => 'Shachi::Model::List' };

    my $metadata_conditions = [];
    foreach my $metadata ( @$metadata_list ) {
        my $value_ids = $query->valid_value_ids($metadata->name);
        next unless @$value_ids;
        push @$metadata_conditions, { -and => {
            metadata_id => $metadata->id,
            value_id    => $_,
        } } for @$value_ids;
    }

    return $metadata_conditions;
}

sub _no_information_conditions {
    args my $class => 'ClassName',
         my $query => { isa => 'Shachi::FacetSearchQuery' },
         my $metadata_list => { isa => 'Shachi::Model::List' };

    # no information を指定しているmetadataを取得
    my $metadata_by_name = $metadata_list->hash_by('name');
    my $no_info_metadata_ids = [ map {
        my $metadata = $metadata_by_name->{$_};
        $metadata ? $metadata->id : ()
    } @{$query->no_info_metadata_names} ];
    return unless @$no_info_metadata_ids;

    my $sql = SQL::Abstract->new;
    my ($sub_sql, @sub_bind) = $sql->select('resource_metadata', 'resource_id', {
        metadata_id => { -in => $no_info_metadata_ids }
    });
    ["NOT IN ($sub_sql)" => @sub_bind];
}

sub search_by_keyword {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $query => { isa => 'Shachi::FacetSearchQuery' },
         my $resource_ids => { isa => 'ArrayRef' };

    return $resource_ids unless $query->has_keyword;
    return $resource_ids unless @$resource_ids;

    my $metadata_for_keyword = Shachi::Service::Metadata->find_by_names(
        db => $db, names => KEYWORD_SEARCH_METADATA_NAMES,
    );
    my ($sql, @bind) = $db->shachi->table('resource_metadata')->select('resource_id')->search({
        resource_id => { -in => $resource_ids },
        metadata_id => { -in => $metadata_for_keyword->map('id')->to_a },
    })->select_sql;
    $sql .= ' AND ' . $query->search_query_sql . ' GROUP BY resource_id';
    my $sth = $db->shachi->dbh->prepare($sql);
    $sth->execute(@bind);

    [ keys %{$sth->fetchall_hashref('resource_id')} ];
}

sub embed_metadata_counts {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $resource_ids  => { optional => 1 },
         my $mode  => { isa => 'Str', default => 'default' };

    $class->embed_metadata_value_with_count(
        db => $db, metadata_list => $metadata_list, resource_ids => $resource_ids, mode => $mode,
    );
    $class->embed_no_metadata_resource_count(
        db => $db, metadata_list => $metadata_list, resource_ids => $resource_ids, mode => $mode,
    );
}

sub embed_metadata_value_with_count {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $resource_ids  => { optional => 1 },
         my $mode  => { isa => 'Str', default => 'default' };

    my $conditions = {
        metadata_id => { -in => $metadata_list->map('id')->to_a },
        status      => { '!=' => 'private' },
    };
    # resource_ids がある場合は resource_ids優先
    # ない場合、mode=asia ならAsiaリソースに限定する
    if ( $resource_ids ) {
        $conditions->{resource_id} = { -in => $resource_ids };
    } elsif ( $mode eq 'asia' ) {
        my $subquery = Shachi::Service::Asia->resource_ids_subquery(db => $db);
        $conditions->{resource_id} = \$subquery;
    }
    my $resource_metadata_counts = $db->shachi->table('resource_metadata')
        ->select(\'COUNT(DISTINCT(resource_id)) as count, metadata_id, value_id')
        ->left_join('resource', { resource_id => 'id' })
            ->search($conditions)->group_by('metadata_id, value_id')->list;
    my $resource_metadata_by_metadata_and_value = $resource_metadata_counts->hash_by(sub {
        $_->metadata_id . '_' . $_->value_id
    });

    my $values_by_type = Shachi::Service::Metadata::Value->find_by_ids(
        db => $db, ids => $resource_metadata_counts->map('value_id')->to_a,
        order => 'value asc',
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
         my $resource_ids  => { optional => 1 },
         my $mode  => { isa => 'Str', default => 'default' };

    my $resource_count = $resource_ids ? scalar @$resource_ids :
        Shachi::Service::Resource->count_not_private(db => $db, mode => $mode);

    my $conditions = {
        metadata_id => { -in => $metadata_list->map('id')->to_a },
        status      => { '!=' => 'private' },
    };
    # resource_ids がある場合は resource_ids優先
    # ない場合、mode=asia ならAsiaリソースに限定する
    if ( $resource_ids ) {
        $conditions->{resource_id} = { -in => $resource_ids };
    } elsif ( $mode eq 'asia' ) {
        my $subquery = Shachi::Service::Asia->resource_ids_subquery(db => $db);
        $conditions->{resource_id} = \$subquery;
    }
    my $has_metadata_count = $db->shachi->table('resource_metadata')
        ->select(\'COUNT(DISTINCT(resource_id)) as count, metadata_id')
        ->left_join('resource', { resource_id => 'id' })
            ->search($conditions)->group_by('metadata_id')->list;
    my $count_by_metadata_id = $has_metadata_count->hash_by('metadata_id');

    foreach my $metadata ( @$metadata_list ) {
        my $resource_metadata = $count_by_metadata_id->{$metadata->id};
        my $count = $resource_metadata ? $resource_metadata->{count} || 0 : 0;
        $metadata->no_metadata_resource_count($resource_count - $count);
    }

    return $metadata_list;
}

1;
