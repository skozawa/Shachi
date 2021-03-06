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
    my %args = @_;
    my $metadata = create_metadata(
        value_type => $args{value_type}, $args{name} ? (name => $args{name}) : ()
    );
    my $values = [ map { create_metadata_value(value_type => $args{value_type}) } (1..$args{value_num}) ];
    my $value_list = Shachi::Model::List->new(list => $values)->sort_by(sub { $_->value }, sub { $_[0]->[1] cmp $_[1]->[1] });
    return ($metadata, $value_list);
};

sub search : Tests {
    truncate_db;
    # Data Preparation
    # metadata1: value1, value2, value3
    my ($metadata1, $metadata1_values) = $create_metadata_and_values->(
        name => 'type', value_type => VALUE_TYPE_ROLE, value_num => 3,
    );
    # metadata2: value1, value2
    my ($metadata2, $metadata2_values) = $create_metadata_and_values->(
        name => 'contributor_author_level', value_type => VALUE_TYPE_LEVEL, value_num => 2,
    );
    my $resources = [ map { create_resource } (1..10) ];
    set_asia($resources->[$_]) for (5..9);
    # resource1: metadata1-value1
    # resource2: metadata1-value2, metadata2-value1
    # resource3: metadata1-value2, metadata2-value2, has_keyword
    # resource4: metadata1-value1
    # resource5: metadata1-value2, metadata2-value2
    # resource6: metadata1-value1, metadata2-value1
    # resource7: has_keyword
    # resource8: metadata1-value1, metadata1-value2
    # resource9: metadata2-value1
    # resource10: metadata1-value1, metadata2-value1, has_keyword

    # metadata1
    for ([0, 0], [1, 1], [2, 1], [3, 0],[4, 1], [5, 0], [7, 0], [7, 1], [9, 0]) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata1, value_id => $metadata1_values->[$_->[1]]->id);
    }
    # metadata2
    for ([1, 0], [2, 1], [4, 1], [5, 0], [8, 0], [9, 0]) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata2, value_id => $metadata2_values->[$_->[1]]->id);
    }
    my $keyword = random_word;
    my $title = create_metadata(name => METADATA_TITLE);
    for ( (2, 6, 9) ) {
        create_resource_metadata(resource => $resources->[$_], metadata => $title, content => $keyword);
    }

    my $db = Shachi::Database->new;

    subtest 'search by metadata' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query([$metadata1->name, $metadata1_values->[0]->id], ['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list,
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[0]->id, $resources->[3]->id];
        is $query->search_count, 5;
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->resource_count, 5;
        is $metadata_list->[0]->values->[1]->resource_count, 1;
        ok ! $metadata_list->[0]->no_metadata_resource_count;
        is scalar @{$metadata_list->[1]->values}, 1;
        is $metadata_list->[1]->values->[0]->resource_count, 2;
        is $metadata_list->[1]->no_metadata_resource_count, 3;
    };

    subtest 'search by no information' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query([$metadata2->name, 0], ['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list,
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[0]->id, $resources->[3]->id];
        is $query->search_count, 4;
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->resource_count, 3;
        is $metadata_list->[0]->values->[1]->resource_count, 1;
        is $metadata_list->[0]->no_metadata_resource_count, 1;
        is scalar @{$metadata_list->[1]->values}, 0;
        is $metadata_list->[1]->no_metadata_resource_count, 4;
    };

    subtest 'search by keyword' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query(['keyword', $keyword], ['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list,
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[2]->id, $resources->[6]->id];
        is $query->search_count, 3;
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->resource_count, 1;
        is $metadata_list->[0]->values->[1]->resource_count, 1;
        is $metadata_list->[0]->no_metadata_resource_count, 1;
        is scalar @{$metadata_list->[1]->values}, 2;
        is $metadata_list->[1]->values->[0]->resource_count, 1;
        is $metadata_list->[1]->values->[1]->resource_count, 1;
        is $metadata_list->[1]->no_metadata_resource_count, 1;
    };

    subtest 'no query' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query(['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list,
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[0]->id, $resources->[1]->id];
        is $query->search_count, 10;
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->resource_count, 5;
        is $metadata_list->[0]->values->[1]->resource_count, 4;
        is $metadata_list->[0]->no_metadata_resource_count, 2;
        is scalar @{$metadata_list->[1]->values}, 2;
        is $metadata_list->[1]->values->[0]->resource_count, 4;
        is $metadata_list->[1]->values->[1]->resource_count, 2;
        is $metadata_list->[1]->no_metadata_resource_count, 4;
    };

    subtest 'search by metadata (asia)' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query([$metadata1->name, $metadata1_values->[0]->id], ['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[5]->id, $resources->[7]->id];
        is $query->search_count, 3;
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->resource_count, 3;
        is $metadata_list->[0]->values->[1]->resource_count, 1;
        ok ! $metadata_list->[0]->no_metadata_resource_count;
        is scalar @{$metadata_list->[1]->values}, 1;
        is $metadata_list->[1]->values->[0]->resource_count, 2;
        is $metadata_list->[1]->no_metadata_resource_count, 1;
    };

    subtest 'search by no information (asia)' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query([$metadata2->name, 0], ['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[6]->id, $resources->[7]->id];
        is $query->search_count, 2;
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->resource_count, 1;
        is $metadata_list->[0]->values->[1]->resource_count, 1;
        is $metadata_list->[0]->no_metadata_resource_count, 1;
        is scalar @{$metadata_list->[1]->values}, 0;
        is $metadata_list->[1]->no_metadata_resource_count, 2;
    };

    subtest 'search by keyword (asia)' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query(['keyword', $keyword], ['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[6]->id, $resources->[9]->id];
        is $query->search_count, 2;
        is scalar @{$metadata_list->[0]->values}, 1;
        is $metadata_list->[0]->values->[0]->resource_count, 1;
        is $metadata_list->[0]->no_metadata_resource_count, 1;
        is scalar @{$metadata_list->[1]->values}, 1;
        is $metadata_list->[1]->values->[0]->resource_count, 1;
        is $metadata_list->[1]->no_metadata_resource_count, 1;
    };

    subtest 'no query' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2]);
        my $query = create_facet_search_query(['limit', 2]);

        my $searched_resources = Shachi::Service::FacetSearch->search(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$searched_resources, 2;
        is_deeply $searched_resources->map('id')->to_a, [$resources->[5]->id, $resources->[6]->id];
        is $query->search_count, 5;
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->resource_count, 3;
        is $metadata_list->[0]->values->[1]->resource_count, 1;
        is $metadata_list->[0]->no_metadata_resource_count, 2;
        is scalar @{$metadata_list->[1]->values}, 1;
        is $metadata_list->[1]->values->[0]->resource_count, 3;
        is $metadata_list->[1]->no_metadata_resource_count, 2;
    };
}

sub search_by_metadata : Tests {
    truncate_db;
    # Data preparation
    # metadata1: value1, value2, value3
    my ($metadata1, $metadata1_values) = $create_metadata_and_values->(
        name => 'type', value_type => VALUE_TYPE_ROLE, value_num => 3,
    );
    # metadata2: value1, value2
    my ($metadata2, $metadata2_values) = $create_metadata_and_values->(
        name => 'contributor_author_level', value_type => VALUE_TYPE_LEVEL, value_num => 2,
    );
    # metadata3: value1, value2, value3
    my ($metadata3, $metadata3_values) = $create_metadata_and_values->(
        name => 'form', value_type => VALUE_TYPE_FORM, value_num => 3,
    );
    my $resources = [ map { create_resource } (1..5) ];
    set_asia($resources->[$_]) for (0,1,2);
    # metadata1
    for ([0, 0], [1, 1], [2, 1], [3, 0],[4, 1]) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata1, value_id => $metadata1_values->[$_->[1]]->id);
    }
    # metadata2
    for ([1, 0], [2, 1], [4, 1]) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata2, value_id => $metadata2_values->[$_->[1]]->id);
    }
    # metadata3
    for ([0, 0], [1, 0], [3, 1], [4, 2]) {
        create_resource_metadata(resource => $resources->[$_->[0]], metadata => $metadata3, value_id => $metadata3_values->[$_->[1]]->id);
    }

    my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
    # resource1: metadata1-value1, metadata3-value1
    # resource2: metadata1-value2, metadata2-value1, metadata3-value1
    # resource3: metadata1-value2, metadata2-value2
    # resource4: metadata1-value1, metadata3-value2
    # resource5: metadata1-value2, metadata2-value2, metadata3-value3

    # search resource3 and resource5 by metadata1-value2 and metadata2-value2
    subtest 'search by certain metadata values' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(
            [$metadata1->name, $metadata1_values->[1]->id],
            [$metadata2->name, $metadata2_values->[1]->id],
        );
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list,
        );
        is scalar @$resource_ids, 2;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [$resources->[2]->id, $resources->[4]->id];
    };

    subtest 'search by certain metadata values (asia)' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(
            [$metadata1->name, $metadata1_values->[1]->id],
            [$metadata2->name, $metadata2_values->[1]->id],
        );
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$resource_ids, 1;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [$resources->[2]->id];
    };

    # search resource1 and resource4 by no infromation for metadata2
    subtest 'search by no information metadata' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query([$metadata2->name, 0]);
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list
        );
        is scalar @$resource_ids, 2;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [$resources->[0]->id, $resources->[3]->id];
    };

    subtest 'search by no information metadata (asia)' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query([$metadata2->name, 0]);
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$resource_ids, 1;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [$resources->[0]->id];
    };

    # search resource1 by metadata3-value1 and no information for metadata2
    subtest 'search by metadata and no information' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(
            [$metadata3->name, $metadata3_values->[0]->id],
            [$metadata2->name, 0]
        );
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list
        );
        is scalar @$resource_ids, 1;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [$resources->[0]->id];
    };

    subtest 'search by metadata and no information (asia)' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(
            [$metadata3->name, $metadata3_values->[0]->id],
            [$metadata2->name, 0]
        );
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$resource_ids, 1;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [$resources->[0]->id];
    };

    # not found by metadata1-value1 and metadata3-value3
    subtest 'not match query' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(
            [$metadata1->name, $metadata1_values->[0]->id],
            [$metadata3->name, $metadata3_values->[2]->id],
        );
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list
        );
        is scalar @$resource_ids, 0;
    };

    subtest 'not match query (asia)' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(
            [$metadata1->name, $metadata1_values->[0]->id],
            [$metadata3->name, $metadata3_values->[2]->id],
        );
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$resource_ids, 0;
    };

    subtest 'no query' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query;
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list,
        );
        is scalar @$resource_ids, 5;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [ map { $_->id } @$resources ];
    };

    subtest 'no query (asia)' => sub {
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query;
        my $resource_ids = Shachi::Service::FacetSearch->search_by_metadata(
            db => $db, query => $query, metadata_list => $metadata_list, mode => 'asia',
        );
        is scalar @$resource_ids, 3;
        is_deeply [ sort { $a <=> $b } @$resource_ids ], [$resources->[0]->id, $resources->[1]->id, $resources->[2]->id];
    };
}

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
            { -and => { metadata_name => $metadata1->name, value_id => 2 } },
            { -and => { metadata_name => $metadata2->name, value_id => 5 } },
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
            { -and => { metadata_name => $metadata2->name, value_id => 5 } },
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
            { -and => { metadata_name => $metadata1->name, value_id => 2 } },
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
            "NOT IN (SELECT resource_id FROM resource_metadata WHERE ( metadata_name IN ( ?, ? ) ))",
            $metadata1->name, $metadata2->name,
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

sub search_by_keyword : Tests {
    truncate_db;
    my $title = create_metadata(name => METADATA_TITLE);
    my $title_abbreviation = create_metadata(name => METADATA_TITLE_ABBREVIATION);
    my $title_alternative = create_metadata(name => METADATA_TITLE_ALTERNATIVE);
    my $description = create_metadata(name => METADATA_DESCRIPTION);
    my $type_purpose = create_metadata(name => METADATA_TYPE_PURPOSE);

    subtest 'contains title' => sub {
        my $keyword = random_word;
        my $resource = create_resource;
        create_resource_metadata(resource => $resource, metadata => $title, content => $keyword);
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(['keyword', $keyword]);

        my $ids = Shachi::Service::FacetSearch->search_by_keyword(
            db => $db, query => $query, resource_ids => [$resource->id],
        );
        is scalar @$ids, 1;
        is_deeply $ids, [ $resource->id ];
    };

    subtest 'contains title_abbreviation' => sub {
        my $keyword = random_word;
        my $resource = create_resource;
        create_resource_metadata(resource => $resource, metadata => $title_abbreviation, content => $keyword);
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(['keyword', $keyword]);

        my $ids = Shachi::Service::FacetSearch->search_by_keyword(
            db => $db, query => $query, resource_ids => [$resource->id],
        );
        is scalar @$ids, 1;
        is_deeply $ids, [ $resource->id ];
    };

    subtest 'contains title description or type_purpose' => sub {
        my $keyword = random_word;
        my $resource1 = create_resource;
        create_resource_metadata(resource => $resource1, metadata => $description, content => $keyword);
        my $resource2 = create_resource;
        create_resource_metadata(resource => $resource2, content => $keyword);
        my $resource3 = create_resource;
        create_resource_metadata(resource => $resource3, metadata => $type_purpose, content => $keyword);
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(['keyword', $keyword]);

        my $ids = Shachi::Service::FacetSearch->search_by_keyword(
            db => $db, query => $query, resource_ids => [$resource1->id, $resource2->id, $resource3->id]
        );
        is scalar @$ids, 2;
        is_deeply [ sort { $a <=> $b } @$ids ], [$resource1->id, $resource3->id];
    };

    subtest 'no resource_ids' => sub {
        my $keyword = random_word;
        my $resource1 = create_resource;
        create_resource_metadata(resource => $resource1, metadata => $description, content => $keyword);
        my $resource2 = create_resource;
        create_resource_metadata(resource => $resource2, metadata => $type_purpose, content => $keyword);
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query(['keyword', $keyword]);

        my $ids = Shachi::Service::FacetSearch->search_by_keyword(
            db => $db, query => $query, resource_ids => []
        );
        is scalar @$ids, 0;
    };

    subtest 'no keyword' => sub {
        my $keyword = random_word;
        my $resource1 = create_resource;
        create_resource_metadata(resource => $resource1, metadata => $description, content => $keyword);
        my $resource2 = create_resource;
        create_resource_metadata(resource => $resource2, metadata => $type_purpose, content => $keyword);
        my $db = Shachi::Database->new;
        my $query = create_facet_search_query;

        my $ids = Shachi::Service::FacetSearch->search_by_keyword(
            db => $db, query => $query, resource_ids => [$resource1->id, $resource2->id]
        );
        is scalar @$ids, 2;
        is_deeply $ids, [$resource1->id, $resource2->id];
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

    my ($metadata1, $metadata1_values) = $create_metadata_and_values->(value_type => VALUE_TYPE_ROLE, value_num => 3);
    my ($metadata2, $metadata2_values) = $create_metadata_and_values->(value_type => VALUE_TYPE_LEVEL, value_num => 5);
    my ($metadata3, $metadata3_values) = $create_metadata_and_values->(value_type => VALUE_TYPE_STYLE, value_num => 2);

    my $resources = [ map { create_resource } (1..5) ];
    set_asia($resources->[$_]) for (1,2,3);
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

    subtest 'count metadata value' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
        Shachi::Service::FacetSearch->embed_metadata_value_with_count(
            db => $db, metadata_list => $metadata_list
        );

        # metadata1
        # - first value (2), second value (3), thrid value (0)
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->id, $metadata1_values->[0]->id;
        is $metadata_list->[0]->values->[0]->resource_count, 2;
        is $metadata_list->[0]->values->[1]->id, $metadata1_values->[1]->id;
        is $metadata_list->[0]->values->[1]->resource_count, 3;

        # metadata2
        # - first value (1), second value (0), third value (2), fourth value (0), fifth value (1)
        is scalar @{$metadata_list->[1]->values}, 3;
        is $metadata_list->[1]->values->[0]->id, $metadata2_values->[0]->id;
        is $metadata_list->[1]->values->[0]->resource_count, 1;
        is $metadata_list->[1]->values->[1]->id, $metadata2_values->[2]->id;
        is $metadata_list->[1]->values->[1]->resource_count, 2;
        is $metadata_list->[1]->values->[2]->id, $metadata2_values->[4]->id;
        is $metadata_list->[1]->values->[2]->resource_count, 1;

        # metadata3
        # - first value (3), second value (3)
        is scalar @{$metadata_list->[2]->values}, 2;
        is $metadata_list->[2]->values->[0]->id, $metadata3_values->[0]->id;
        is $metadata_list->[2]->values->[0]->resource_count, 3;
        is $metadata_list->[2]->values->[1]->id, $metadata3_values->[1]->id;
        is $metadata_list->[2]->values->[1]->resource_count, 3;
    };

    subtest 'count metadata value with resource_ids' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
        Shachi::Service::FacetSearch->embed_metadata_value_with_count(
            db => $db, metadata_list => $metadata_list, resource_ids => [ map { $_->id } @$resources ],
        );

        # metadata1
        # - first value (2), second value (3), thrid value (0)
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->id, $metadata1_values->[0]->id;
        is $metadata_list->[0]->values->[0]->resource_count, 2;
        is $metadata_list->[0]->values->[1]->id, $metadata1_values->[1]->id;
        is $metadata_list->[0]->values->[1]->resource_count, 3;

        # metadata2
        # - first value (1), second value (0), third value (2), fourth value (0), fifth value (1)
        is scalar @{$metadata_list->[1]->values}, 3;
        is $metadata_list->[1]->values->[0]->id, $metadata2_values->[0]->id;
        is $metadata_list->[1]->values->[0]->resource_count, 1;
        is $metadata_list->[1]->values->[1]->id, $metadata2_values->[2]->id;
        is $metadata_list->[1]->values->[1]->resource_count, 2;
        is $metadata_list->[1]->values->[2]->id, $metadata2_values->[4]->id;
        is $metadata_list->[1]->values->[2]->resource_count, 1;

        # metadata3
        # - first value (3), second value (3)
        is scalar @{$metadata_list->[2]->values}, 2;
        is $metadata_list->[2]->values->[0]->id, $metadata3_values->[0]->id;
        is $metadata_list->[2]->values->[0]->resource_count, 3;
        is $metadata_list->[2]->values->[1]->id, $metadata3_values->[1]->id;
        is $metadata_list->[2]->values->[1]->resource_count, 3;
    };

    subtest 'count metadata value for asia mode' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
        Shachi::Service::FacetSearch->embed_metadata_value_with_count(
            db => $db, metadata_list => $metadata_list, mode => 'asia',
        );

        # metadata1
        # - first value (1), second value (2), thrid value (0)
        is scalar @{$metadata_list->[0]->values}, 2;
        is $metadata_list->[0]->values->[0]->id, $metadata1_values->[0]->id;
        is $metadata_list->[0]->values->[0]->resource_count, 1;
        is $metadata_list->[0]->values->[1]->id, $metadata1_values->[1]->id;
        is $metadata_list->[0]->values->[1]->resource_count, 2;

        # metadata2
        # - first value (0), second value (0), third value (2), fourth value (0), fifth value (0)
        is scalar @{$metadata_list->[1]->values}, 1;
        is $metadata_list->[1]->values->[0]->id, $metadata2_values->[2]->id;
        is $metadata_list->[1]->values->[0]->resource_count, 2;

        # metadata3
        # - first value (2), second value (2)
        is scalar @{$metadata_list->[2]->values}, 2;
        is $metadata_list->[2]->values->[0]->id, $metadata3_values->[0]->id;
        is $metadata_list->[2]->values->[0]->resource_count, 2;
        is $metadata_list->[2]->values->[1]->id, $metadata3_values->[1]->id;
        is $metadata_list->[2]->values->[1]->resource_count, 2;
    };
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

    my ($metadata1, $metadata1_values) = $create_metadata_and_values->(value_type => VALUE_TYPE_ROLE, value_num => 3);
    my ($metadata2, $metadata2_values) = $create_metadata_and_values->(value_type => VALUE_TYPE_LEVEL, value_num => 5);
    my ($metadata3, $metadata3_values) = $create_metadata_and_values->(value_type => VALUE_TYPE_STYLE, value_num => 2);

    my $resources = [ map { create_resource } (1..5) ];
    set_asia($resources->[$_]) for (1,2,3);

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

    subtest 'count no information' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
        Shachi::Service::FacetSearch->embed_no_metadata_resource_count(
            db => $db, metadata_list => $metadata_list
        );

        is $metadata_list->[0]->no_metadata_resource_count, 2;
        is $metadata_list->[1]->no_metadata_resource_count, 1;
        ok ! $metadata_list->[2]->no_metadata_resource_count;
    };

    subtest 'count no information with resource_ids' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
        Shachi::Service::FacetSearch->embed_no_metadata_resource_count(
            db => $db, metadata_list => $metadata_list, resource_ids => [ map { $_->id } @$resources ],
        );

        is $metadata_list->[0]->no_metadata_resource_count, 2;
        is $metadata_list->[1]->no_metadata_resource_count, 1;
        ok ! $metadata_list->[2]->no_metadata_resource_count;
    };

    subtest 'count no information for asia' => sub {
        my $metadata_list = Shachi::Model::List->new(list => [$metadata1, $metadata2, $metadata3]);
        Shachi::Service::FacetSearch->embed_no_metadata_resource_count(
            db => $db, metadata_list => $metadata_list, mode => 'asia',
        );

        is $metadata_list->[0]->no_metadata_resource_count, 1;
        is $metadata_list->[1]->no_metadata_resource_count, 1;
        ok ! $metadata_list->[2]->no_metadata_resource_count;
    };
}
