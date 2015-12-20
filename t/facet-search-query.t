package t::Shachi::FacetSearchQuery;
use t::test;
use Hash::MultiValue;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::FacetSearchQuery';
}

sub search_query_sql : Tests {
    subtest 'one keyword' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => 'corpus');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is $query->search_query_sql, "content REGEXP 'corpus'";
    };

    subtest 'and query' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => 'corpus text');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is $query->search_query_sql, "content REGEXP 'corpus' AND content REGEXP 'text'";
    };

    subtest 'or query' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => 'corpus OR text');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is $query->search_query_sql, "content REGEXP 'corpus' OR content REGEXP 'text'";
    };

    subtest 'phrase' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => '"text corpus"');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is $query->search_query_sql, "content REGEXP 'text corpus'";
    };

    subtest 'and or query' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => '(text OR speech) corpus');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is $query->search_query_sql, "(content REGEXP 'text' OR content REGEXP 'speech') AND content REGEXP 'corpus'";
    };
}

sub value_ids : Tests {
    subtest 'has value' => sub {
        my $params = Hash::MultiValue->new;
        my $name = 'language_area';
        $params->add($name => 4);
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is_deeply $query->value_ids($name), [4];
    };

    subtest 'has zero value' => sub {
        my $params = Hash::MultiValue->new;
        my $name = 'language_area';
        $params->add($name => 0);
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is_deeply $query->value_ids($name), [0];
    };

    subtest 'no value' => sub {
        my $params = Hash::MultiValue->new;
        my $name = 'language_area';
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is_deeply $query->value_ids($name), [];
    };
}

sub valid_value_ids : Tests {
    subtest 'has value' => sub {
        my $params = Hash::MultiValue->new;
        my $name = 'language_area';
        $params->add($name => 4);
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is_deeply $query->valid_value_ids($name), [4];
    };

    subtest 'has zero value' => sub {
        my $params = Hash::MultiValue->new;
        my $name = 'language_area';
        $params->add($name => 0);
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is_deeply $query->valid_value_ids($name), [];
    };

    subtest 'no value' => sub {
        my $params = Hash::MultiValue->new;
        my $name = 'language_area';
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is_deeply $query->valid_value_ids($name), [];
    };
}

sub keyword : Tests {
    subtest 'keyword' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => 'corpus');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        is $query->keyword, 'corpus';
    };
}

sub has_keyword : Tests {
    subtest 'has keyword' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => 'corpus');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        ok $query->has_keyword;
    };

    subtest 'empty keyword' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => '');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        ok ! $query->has_keyword;
    };

    subtest 'no keyword' => sub {
        my $params = Hash::MultiValue->new;
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        ok ! $query->has_keyword;
    };
}

sub has_any_query {
    subtest 'has keyword query' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('keyword' => 'corpus');
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        ok $query->has_any_query;
    };

    subtest 'has facet query' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('language_area' => 4);
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        ok $query->has_any_query;
    };

    subtest 'no query' => sub {
        my $params = Hash::MultiValue->new;
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        ok ! $query->has_any_query;
    };
}

sub no_info_metadata_names : Tests {
    subtest '0 value metadata names' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('language_area' => 0);
        $params->add('type' => 43);
        $params->add('type_annotation' => 0);
        $params->add('language' => 100);
        my $query = Shachi::FacetSearchQuery->new(params => $params);

        cmp_deeply [ sort @{$query->no_info_metadata_names} ], [ 'language_area', 'type_annotation' ];
    };
}

sub current_page_num : Tests {
    subtest 'default' => sub {
        my $params = Hash::MultiValue->new;
        my $query  = Shachi::FacetSearchQuery->new(params => $params);

        is $query->current_page_num, 1;
    };

    subtest 'offset 50, limit 10' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('offset' => 50);
        $params->add('limit'  => 10);
        my $query  = Shachi::FacetSearchQuery->new(params => $params);
        is $query->current_page_num, 6;
    };

    subtest 'offset 50, limit 20' => sub {
        my $params = Hash::MultiValue->new;
        $params->add('offset' => 50);
        $params->add('limit'  => 20);
        my $query  = Shachi::FacetSearchQuery->new(params => $params);
        is $query->current_page_num, 3;
    };
}

sub has_page : Tests {
    my $params = Hash::MultiValue->new;
    $params->add('offset' => 0);
    $params->add('limit'  => 10);
    my $query  = Shachi::FacetSearchQuery->new(params => $params);

    ok ! $query->has_page(-1), 'minus';
    ok ! $query->has_page(1), 'no search count';

    $query->search_count(100);

    ok $query->has_page(5), 'has page';
    ok ! $query->has_page(20), 'large page number';
}
