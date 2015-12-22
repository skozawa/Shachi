package t::Shachi::Service::FacetSearch;
use t::test;
use Shachi::Database;
use Shachi::FacetSearchQuery;
use Shachi::Model::List;
use Shachi::Model::Metadata;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::FacetSearch';
}

my $create_metadata_and_values = sub {
    my ($value_type, $value_num) = @_;
    my $metadata = create_metadata(value_type => $value_type);
    my $values = [ map { create_metadata_value(value_type => $value_type) } (1..$value_num) ];
    my $value_list = Shachi::Model::List->new(list => $values)->sort_by(sub { $_->value }, sub { $_[0]->[1] cmp $_[1]->[1] });
    return ($metadata, $value_list);
};


sub _metadata_conditions : Tests {
    subtest 'has metadata valeu' => sub {
        my $metadata1 = create_metadata;
        my $metadata2 = create_metadata;
        my $query = create_facet_search_query([$metadata1->name, 2], [$metadata2->name, 5]);

        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $conditions = Shachi::Service::FacetSearch->_metadata_conditions(
            query => $query, metadata_list => $metadata_list,
        );
        cmp_deeply $conditions, [
            { -and => { metadata_id => $metadata1->id, value_id => 2 } },
            { -and => { metadata_id => $metadata2->id, value_id => 5 } },
        ];
    };

    subtest 'no information' => sub {
        my $metadata1 = create_metadata;
        my $metadata2 = create_metadata;
        my $query = create_facet_search_query([$metadata1->name, 0], [$metadata2->name, 5]);

        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $conditions = Shachi::Service::FacetSearch->_metadata_conditions(
            query => $query, metadata_list => $metadata_list,
        );
        cmp_deeply $conditions, [
            { -and => { metadata_id => $metadata2->id, value_id => 5 } },
        ];
    };

    subtest 'only metadata_list value' => sub {
        my $metadata1 = create_metadata;
        my $metadata2 = create_metadata;
        my $query = create_facet_search_query([$metadata1->name, 2], [$metadata2->name, 5]);

        my $metadata_list = Shachi::Model::List->new(list => [$metadata1]);
        my $conditions = Shachi::Service::FacetSearch->_metadata_conditions(
            query => $query, metadata_list => $metadata_list,
        );
        cmp_deeply $conditions, [
            { -and => { metadata_id => $metadata1->id, value_id => 2 } },
        ];
    };
}

sub _no_information_conditions : Tests {
    subtest 'no information conditions' => sub {
        truncate_db;
        my $metadata1 = create_metadata(name => 'type');
        my $metadata2 = create_metadata(name => 'type_form');
        my $query = create_facet_search_query([$metadata1->name, 0], [$metadata2->name, 0]);
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);

        my $no_info_conditions = Shachi::Service::FacetSearch->_no_information_conditions(
            query => $query, metadata_list => $metadata_list,
        );
        cmp_deeply $no_info_conditions, [
            "NOT IN (SELECT resource_id FROM resource_metadata WHERE ( metadata_id IN ( ?, ? ) ))",
            $metadata1->id, $metadata2->id,
        ];
    };

    subtest 'not facet metadata' => sub {
        truncate_db;
        my $metadata1 = create_metadata;
        my $metadata2 = create_metadata;
        my $query = create_facet_search_query([$metadata1->name, 0], [$metadata2->name, 0]);
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);

        my $no_info_conditions = Shachi::Service::FacetSearch->_no_information_conditions(
            query => $query, metadata_list => $metadata_list,
        );
        ok ! $no_info_conditions;
    };

    subtest 'do not have no information metadata' => sub {
        truncate_db;
        my $metadata1 = create_metadata(name => 'type');
        my $metadata2 = create_metadata(name => 'type_form');
        my $query = create_facet_search_query([$metadata1->name, 2], [$metadata2->name, 3]);
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);

        my $no_info_conditions = Shachi::Service::FacetSearch->_no_information_conditions(
            query => $query, metadata_list => $metadata_list,
        );
        ok ! $no_info_conditions;
    };
}

# metadata1
# - first value (2)
# - second value (3)
# - thrid value (0)
# metadata2
# - first value (1)
# - second value (0)
# - third value (2)
# - fourth value (0)
# - fifth value (1)
# metadata3 - two values
# - first value (3)
# - second value (3)
sub embed_metadata_value_with_count : Tests {
    truncate_db;

    my ($metadata1, $metadata1_values) = $create_metadata_and_values->(VALUE_TYPE_ROLE, 3);
    my ($metadata2, $metadata2_values) = $create_metadata_and_values->(VALUE_TYPE_LEVEL, 5);
    my ($metadata3, $metadata3_values) = $create_metadata_and_values->(VALUE_TYPE_STYLE, 2);

    my $resources = [ map { create_resource } (1..5) ];
    # create resource metadata for metadata1
    for ( [0, 0], [1, 0], [2, 1], [3, 1], [4, 1] ) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata1, value_id => $metadata1_values->[$_->[1]]->id);
    }
    # create resource metadata for metadata2
    for ( [0, 0], [1, 2], [2, 2], [4, 4] ) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata2, value_id => $metadata2_values->[$_->[1]]->id);
    }
    # create resource metadata for metadata3
    for ( [0, 0], [1, 0], [2, 0], [2, 1], [3, 1], [4, 1] ) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata3, value_id => $metadata3_values->[$_->[1]]->id);
    }

    my $db = Shachi::Database->new;
    my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
    Shachi::Service::FacetSearch->embed_metadata_value_with_count(
        db => $db, metadata_list => $metadata_list, resource_ids => [ map { $_->id } @$resources ],
    );

    # metadata1
    # - first value (2)
    # - second value (3)
    # - thrid value (0)
    is scalar @{$metadata1->values}, 2;
    is $metadata1->values->[0]->id, $metadata1_values->[0]->id;
    is $metadata1->values->[0]->resource_count, 2;
    is $metadata1->values->[1]->id, $metadata1_values->[1]->id;
    is $metadata1->values->[1]->resource_count, 3;

    # metadata2
    # - first value (1)
    # - second value (0)
    # - third value (2)
    # - fourth value (0)
    # - fifth value (1)
    is scalar @{$metadata2->values}, 3;
    is $metadata2->values->[0]->id, $metadata2_values->[0]->id;
    is $metadata2->values->[0]->resource_count, 1;
    is $metadata2->values->[1]->id, $metadata2_values->[2]->id;
    is $metadata2->values->[1]->resource_count, 2;
    is $metadata2->values->[2]->id, $metadata2_values->[4]->id;
    is $metadata2->values->[2]->resource_count, 1;

    # metadata3
    # - first value (3)
    # - second value (3)
    is scalar @{$metadata3->values}, 2;
    is $metadata3->values->[0]->id, $metadata3_values->[0]->id;
    is $metadata3->values->[0]->resource_count, 3;
    is $metadata3->values->[1]->id, $metadata3_values->[1]->id;
    is $metadata3->values->[1]->resource_count, 3;
}

# metadata1
# - no information (2)
# - first value (2), second value (1), thrid value (0)
# metadata2
# - no informatioin (1)
# - first value (1), second value (0), third value (2), fourth value (0), fifth value (1)
# metadata3
# - no information (0)
# - first value (3), second value (3)
sub embed_no_metadata_resource_count : Tests {
    truncate_db;

    my ($metadata1, $metadata1_values) = $create_metadata_and_values->(VALUE_TYPE_ROLE, 3);
    my ($metadata2, $metadata2_values) = $create_metadata_and_values->(VALUE_TYPE_LEVEL, 5);
    my ($metadata3, $metadata3_values) = $create_metadata_and_values->(VALUE_TYPE_STYLE, 2);

    my $resources = [ map { create_resource } (1..5) ];
    # create resource metadata for metadata1
    for ( [0, 0], [1, 0], [2, 1] ) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata1, value_id => $metadata1_values->[$_->[1]]->id);
    }
    # create resource metadata for metadata2
    for ( [0, 0], [1, 2], [2, 2], [4, 4] ) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata2, value_id => $metadata2_values->[$_->[1]]->id);
    }
    # create resource metadata for metadata3
    for ( [0, 0], [1, 0], [2, 0], [2, 1], [3, 1], [4, 1] ) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata3, value_id => $metadata3_values->[$_->[1]]->id);
    }

    my $db = Shachi::Database->new;
    my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
    Shachi::Service::FacetSearch->embed_no_metadata_resource_count(
        db => $db, metadata_list => $metadata_list, resource_ids => [ map { $_->id } @$resources ],
    );

    is $metadata1->no_metadata_resource_count, 2;
    is $metadata2->no_metadata_resource_count, 1;
    ok ! $metadata3->no_metadata_resource_count;
}
