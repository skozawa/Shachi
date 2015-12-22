package t::Shachi::FacetSearchQuery;
use t::test;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::FacetSearchQuery';
}

sub search_query_sql : Tests {
    subtest 'one keyword' => sub {
        my $query = create_facet_search_query(['keyword', 'corpus']);
        is $query->search_query_sql, "content REGEXP 'corpus'";
    };

    subtest 'and query' => sub {
        my $query = create_facet_search_query(['keyword', 'corpus text']);
        is $query->search_query_sql, "content REGEXP 'corpus' AND content REGEXP 'text'";
    };

    subtest 'or query' => sub {
        my $query = create_facet_search_query(['keyword', 'corpus OR text']);
        is $query->search_query_sql, "content REGEXP 'corpus' OR content REGEXP 'text'";
    };

    subtest 'phrase' => sub {
        my $query = create_facet_search_query(['keyword', '"text corpus"']);
        is $query->search_query_sql, "content REGEXP 'text corpus'";
    };

    subtest 'and or query' => sub {
        my $query = create_facet_search_query(['keyword', '(text OR speech) corpus']);
        is $query->search_query_sql, "(content REGEXP 'text' OR content REGEXP 'speech') AND content REGEXP 'corpus'";
    };
}

sub value_ids : Tests {
    subtest 'has value' => sub {
        my $name = 'language_area';
        my $query = create_facet_search_query([$name, 4]);
        is_deeply $query->value_ids($name), [4];
    };

    subtest 'has zero value' => sub {
        my $name = 'language_area';
        my $query = create_facet_search_query([$name, 0]);
        is_deeply $query->value_ids($name), [0];
    };

    subtest 'no value' => sub {
        my $name = 'language_area';
        my $query = create_facet_search_query;
        is_deeply $query->value_ids($name), [];
    };
}

sub valid_value_ids : Tests {
    subtest 'has value' => sub {
        my $name = 'language_area';
        my $query = create_facet_search_query([$name, 4]);
        is_deeply $query->valid_value_ids($name), [4];
    };

    subtest 'has zero value' => sub {
        my $name = 'language_area';
        my $query = create_facet_search_query([$name, 0]);
        is_deeply $query->valid_value_ids($name), [];
    };

    subtest 'no value' => sub {
        my $name = 'language_area';
        my $query = create_facet_search_query;
        is_deeply $query->valid_value_ids($name), [];
    };
}

sub keyword : Tests {
    subtest 'keyword' => sub {
        my $query = create_facet_search_query(['keyword', 'corpus']);
        is $query->keyword, 'corpus';
    };
}

sub has_keyword : Tests {
    subtest 'has keyword' => sub {
        my $query = create_facet_search_query(['keyword', 'corpus']);
        ok $query->has_keyword;
    };

    subtest 'empty keyword' => sub {
        my $query = create_facet_search_query(['keyword', '']);
        ok ! $query->has_keyword;
    };

    subtest 'no keyword' => sub {
        my $query = create_facet_search_query;
        ok ! $query->has_keyword;
    };
}

sub has_any_query {
    subtest 'has keyword query' => sub {
        my $query = create_facet_search_query(['keyword', 'corpus']);
        ok $query->has_any_query;
    };

    subtest 'has facet query' => sub {
        my $query = create_facet_search_query(['language_area', 4]);
        ok $query->has_any_query;
    };

    subtest 'no query' => sub {
        my $query = create_facet_search_query;
        ok ! $query->has_any_query;
    };
}

sub no_info_metadata_names : Tests {
    subtest '0 value metadata names' => sub {
        my $query = create_facet_search_query(
            ['language_area', 0], ['type', 43], ['type_annotation', 0], ['language', 100]
        );
        cmp_deeply [ sort @{$query->no_info_metadata_names} ], [ 'language_area', 'type_annotation' ];
    };
}

sub current_page_num : Tests {
    subtest 'default' => sub {
        my $query = create_facet_search_query;
        is $query->current_page_num, 1;
    };

    subtest 'offset 50, limit 10' => sub {
        my $query = create_facet_search_query(['offset', 50], ['limit', 10]);
        is $query->current_page_num, 6;
    };

    subtest 'offset 50, limit 20' => sub {
        my $query = create_facet_search_query(['offset', 50], ['limit', 20]);
        is $query->current_page_num, 3;
    };
}

sub has_page : Tests {
    my $query = create_facet_search_query(['offset', 0], ['limit', 10]);

    ok ! $query->has_page(-1), 'minus';
    ok ! $query->has_page(1), 'no search count';

    $query->search_count(100);

    ok $query->has_page(5), 'has page';
    ok ! $query->has_page(20), 'large page number';
}
