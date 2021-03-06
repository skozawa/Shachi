package t::Shachi::Service::Resource;
use t::test;
use Shachi::Database;
use Shachi::Service::Resource;
use Shachi::Service::Resource::Metadata;
use Shachi::Model::Language;
use Shachi::Model::Metadata;
use Shachi::Model::Metadata::Value;
use Shachi::Model::Resource;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Resource';
}

sub create : Tests {
    subtest 'create normally' => sub {
        my $db = Shachi::Database->new;
        my $annotator_id = int(rand(10000));

        my $resource = Shachi::Service::Resource->create(db => $db, args => {
            annotator_id => $annotator_id,
        });

        ok $resource;
        isa_ok $resource, 'Shachi::Model::Resource';
        is $resource->annotator_id, $annotator_id, 'equal annotator_id';
        is $resource->status, 'public', 'equal status';
        is $resource->edit_status, EDIT_STATUS_NEW, 'equal edit_status';
        ok $resource->id, 'has id';
        ok $resource->shachi_id, 'has shachi_id';
    };
}

sub shachi_id : Tests {
    subtest 'shachi_id for corpus' => sub {
        my $resource_id = int(rand(10000));
        my $shachi_id = Shachi::Service::Resource->shachi_id(
            resource_id => $resource_id, resource_subject => 'corpus',
        );
        is $shachi_id, sprintf 'C-%06d', $resource_id;
    };

    subtest 'shachi_id for dictionary' => sub {
        my $resource_id = int(rand(10000));
        my $shachi_id = Shachi::Service::Resource->shachi_id(
            resource_id => $resource_id, resource_subject => 'dictionary',
        );
        is $shachi_id, sprintf 'D-%06d', $resource_id;
    };

    subtest 'shachi_id for glossary' => sub {
        my $resource_id = int(rand(10000));
        my $shachi_id = Shachi::Service::Resource->shachi_id(
            resource_id => $resource_id, resource_subject => 'glossary',
        );
        is $shachi_id, sprintf 'G-%06d', $resource_id;
    };

    subtest 'shachi_id for thesaurus' => sub {
        my $resource_id = int(rand(10000));
        my $shachi_id = Shachi::Service::Resource->shachi_id(
            resource_id => $resource_id, resource_subject => 'thesaurus',
        );
        is $shachi_id, sprintf 'T-%06d', $resource_id;
    };

    subtest 'shachi_id for other' => sub {
        my $resource_id = int(rand(10000));
        my $shachi_id = Shachi::Service::Resource->shachi_id(
            resource_id => $resource_id, resource_subject => 'test',
        );
        is $shachi_id, sprintf 'O-%06d', $resource_id;
    };

    subtest 'shachi_id for none' => sub {
        my $resource_id = int(rand(10000));
        my $shachi_id = Shachi::Service::Resource->shachi_id(
            resource_id => $resource_id,
        );
        is $shachi_id, sprintf 'N-%06d', $resource_id;
    };
}

sub find_by_id : Tests {
    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;

        my $found_resource = Shachi::Service::Resource->find_by_id(
            db => $db, id => $resource->id,
        );
        is $resource->id, $found_resource->id;
    };
}

sub find_resource_detail : Tests {
    my $create_data = sub {
        my ($resource) = @_;
        my $english = get_english;
        my $language = create_language;
        my $metadata_list = Shachi::Model::List->new(list => [
            create_metadata(name => METADATA_TITLE),
            create_metadata(name => METADATA_DESCRIPTION),
            create_metadata(name => METADATA_DESCRIPTION_PRICE),
            create_metadata(name => METADATA_IDENTIFIER),
            create_metadata(name => METADATA_LANGUAGE_AREA),
            create_metadata(value_type => VALUE_TYPE_STYLE),
        ]);
        create_resource_metadata(resource => $resource, language => $language,
                                 metadata => $metadata_list->[$_]) for (0..3);
        set_language_area($resource, LANGUAGE_AREA_ASIA, $english);
        set_language_area($resource, LANGUAGE_AREA_JAPAN, $english);
        my $value = create_metadata_value(value_type => VALUE_TYPE_STYLE);
        create_resource_metadata(resource => $resource, language => $english,
                                 metadata => $metadata_list->[5], value_id => $value->id);

        return ($metadata_list, $language);
    };

    my $db = Shachi::Database->new;
    subtest 'find normally' => sub {
        truncate_db_with_setup;
        my $annotator = create_annotator;
        my $resource = create_resource(annotator => $annotator);
        my ($metadata_list, $language) = $create_data->($resource);

        my ($found_resource, $ml) = Shachi::Service::Resource->find_resource_detail(
            db => $db, id => $resource->id, language => $language,
            args => { metadata_list => $metadata_list },
        );
        is $found_resource->id, $resource->id;
        is $found_resource->metadata_list->size, 4;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_TITLE)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_DESCRIPTION)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_DESCRIPTION_PRICE)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_IDENTIFIER)}, 1;
        is $found_resource->annotator->id, $annotator->id;
    };

    subtest 'find normally with fillin_english' => sub {
        truncate_db_with_setup;
        my $annotator = create_annotator;
        my $resource = create_resource(annotator => $annotator);
        my ($metadata_list, $language) = $create_data->($resource);

        my ($found_resource, $ml) = Shachi::Service::Resource->find_resource_detail(
            db => $db, id => $resource->id, language => $language,
            args => { metadata_list => $metadata_list, fillin_english => 1 },
        );
        is $found_resource->id, $resource->id;
        is $found_resource->metadata_list->size, 7;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_TITLE)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_DESCRIPTION)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_DESCRIPTION_PRICE)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_IDENTIFIER)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_LANGUAGE_AREA)}, 2;
        is scalar @{$found_resource->metadata_list_by_name($metadata_list->last->name)}, 1;
        ok $found_resource->metadata_list_by_name($metadata_list->last->name)->[0]->value;
        is $found_resource->annotator->id, $annotator->id;
    };

    subtest 'find normally not include price' => sub {
        truncate_db_with_setup;
        my $annotator = create_annotator;
        my $resource = create_resource(annotator => $annotator, status => STATUS_LIMITED_BY_ELRA);
        my ($metadata_list, $language) = $create_data->($resource);

        my ($found_resource, $ml) = Shachi::Service::Resource->find_resource_detail(
            db => $db, id => $resource->id, language => $language,
            args => { metadata_list => $metadata_list },
        );
        is $found_resource->id, $resource->id;
        is $found_resource->metadata_list->size, 3;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_TITLE)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_DESCRIPTION)}, 1;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_DESCRIPTION_PRICE)}, 0;
        is scalar @{$found_resource->metadata_list_by_name(METADATA_IDENTIFIER)}, 1;
        is $found_resource->annotator->id, $annotator->id;
    };
}

sub count_not_private : Tests {
    truncate_db;
    for (qw/public private limited_by_LDC limited_by_ELRA/) {
        create_resource(status => $_);
        my $r = create_resource(status => $_);
        set_asia($r);
        set_language_area($r, LANGUAGE_AREA_JAPAN);
    }

    my $db = Shachi::Database->new;
    my $count = Shachi::Service::Resource->count_not_private(db => $db);
    is $count, 6;

    my $count_asia = Shachi::Service::Resource->count_not_private(db => $db, mode => 'asia');
    is $count_asia, 3;
}

sub search_all : Tests {
    truncate_db;
    my $resources = [ map { create_resource } (1..10) ];
    create_resource(status => 'private');
    set_asia($resources->[$_]) for (0..4);
    set_language_area($resources->[$_], LANGUAGE_AREA_JAPAN) for (0..2);
    my $db = Shachi::Database->new;

    subtest 'search all' => sub {
        my $resources = Shachi::Service::Resource->search_all(db => $db);
        is_deeply $resources->map('id')->to_a, [ map { $_->id } @$resources ];
    };

    subtest 'search all (asia)' => sub {
        my $resources = Shachi::Service::Resource->search_all(db => $db, mode => 'asia');
        is_deeply $resources->map('id')->to_a, [ map { $resources->[$_]->id } (0..4) ];
    };
}

sub search_titles : Tests {
    truncate_db;
    my $title_metadata = create_metadata(name => METADATA_TITLE);
    my $titles = [
        "Arabic Data Set",
        "Biology Database",
        "Chinese Lexicon",
        "Dictionary of Law",
    ];
    create_resource_metadata(metadata => $title_metadata, content => $_) for @$titles;

    subtest 'search normally' => sub {
        my $db = Shachi::Database->new;
        my $query = 'data';

        my $resources = Shachi::Service::Resource->search_titles(
            db => $db, query => $query,
        );
        is $resources->size, 2;
    };
}

sub embed_title : Tests {
    truncate_db_with_setup;
    my $title_metadata = create_metadata(name => METADATA_TITLE);
    my $english = get_english;

    subtest 'embed title normally' => sub {
        my $db = Shachi::Database->new;
        my $language = create_language;
        my $resource1 = create_resource;
        my $title1 = random_word;
        create_resource_metadata(
            resource => $resource1, metadata => $title_metadata,
            language => $language,  content => $title1
        );

        my $resource2 = create_resource;
        my $title2 = random_word;
        create_resource_metadata(
            resource => $resource2, metadata => $title_metadata,
            language => $language,  content => $title2,
        );

        ok ! $resource1->title;
        ok ! $resource2->title;

        my $resources = Shachi::Service::Resource->embed_title(
            db => $db, language => $language,
            resources => Shachi::Model::List->new(list => [ $resource1, $resource2 ])
        );
        is $resources->[0]->title, $title1;
        is $resources->[1]->title, $title2;
    };

    subtest 'different language' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        my $title = random_word;
        my $language = create_language;
        my $language_other = create_language;
        create_resource_metadata(
            resource => $resource, metadata => $title_metadata,
            language => $language, content  => $title,
        );

        ok ! $resource->title;

        my $resources = Shachi::Service::Resource->embed_title(
            db => $db, language => $language_other, resources => $resource->as_list,
        );
        ok ! $resources->[0]->title;
    };

    subtest 'fillin english' => sub {
        my $db = Shachi::Database->new;
        my $language = create_language;
        my $resource1 = create_resource;
        my $title1 = random_word;
        my $title1_eng = random_word;
        create_resource_metadata(
            resource => $resource1, metadata => $title_metadata,
            language => $language, content => $title1
        );
        create_resource_metadata(
            resource => $resource1, metadata => $title_metadata,
            language => $english, content => $title1_eng,
        );

        my $resource2 = create_resource;
        my $title2_eng = random_word;
        create_resource_metadata(
            resource => $resource2, metadata => $title_metadata,
            language => $english, content => $title2_eng,
        );

        my $resources = Shachi::Service::Resource->embed_title(
            db => $db, language => $language,
            resources => Shachi::Model::List->new(list => [ $resource1, $resource2 ]),
            args => { fillin_english => 1 },
        );
        is $resources->[0]->title, $title1;
        is $resources->[1]->title, $title2_eng;
    };
}

sub embed_relations : Tests {
    truncate_db_with_setup;
    my $relation_metadata = create_metadata(name => METADATA_RELATION);
    my $english = get_english;

    subtest 'embed relation' => sub {
        my $values = [ map { create_metadata_value } (0..5) ];
        my $resources = Shachi::Model::List->new(list => [ map { create_resource } (1..3) ]);
        my $language = create_language;
        for ( [0, 0], [1, 1], [1, 2], [1, 3], [2, 4], [2, 5] ) {
            create_resource_metadata(
                resource => $resources->[$_->[0]], language => $language,
                metadata => $relation_metadata, value_id => $values->[$_->[1]]->id,
            );
        }

        my $db = Shachi::Database->new;
        Shachi::Service::Resource->embed_relations(
            db => $db, resources => $resources, language => $language,
        );

        is scalar @{$resources->[0]->relations || []}, 1;
        is $resources->[0]->relations->[0]->value->id, $values->[0]->id;
        is scalar @{$resources->[1]->relations || []}, 3;
        is scalar @{$resources->[2]->relations || []}, 2;
    };

    subtest 'embed_relation with fillin_english' => sub {
        my $values = [ map { create_metadata_value } (0..5) ];
        my $resources = Shachi::Model::List->new(list => [ map { create_resource } (1..3) ]);
        my $language = create_language;
        create_resource_metadata(
            resource => $resources->[$_->[0]], language => $language,
            metadata => $relation_metadata, value_id => $values->[$_->[1]]->id,
        ) for ( [0, 0], [2, 4] );
        create_resource_metadata(
            resource => $resources->[$_->[0]], language => $english,
            metadata => $relation_metadata, value_id => $values->[$_->[1]]->id,
        ) for ( [1, 1], [1, 2], [1, 3], [2, 5] );

        my $db = Shachi::Database->new;
        Shachi::Service::Resource->embed_relations(
            db => $db, resources => $resources, language => $language,
            args => { fillin_english => 1 },
        );

        is scalar @{$resources->[0]->relations || []}, 1;
        is $resources->[0]->relations->[0]->value->id, $values->[0]->id;
        is scalar @{$resources->[1]->relations || []}, 3;
        is $resources->[1]->relations->[0]->language_id, $english->id;
        is scalar @{$resources->[2]->relations || []}, 1;
        is $resources->[2]->relations->[0]->language_id, $language->id;
    };
}

sub update_annotator : Tests {
    subtest 'update normally' => sub {
        my $db = Shachi::Database->new;
        my $annotator1 = create_annotator;
        my $annotator2 = create_annotator;
        my $resource   = create_resource(annotator_id => $annotator1->id);

        is $resource->annotator_id, $annotator1->id;

        Shachi::Service::Resource->update_annotator(
            db => $db, id => $resource->id, annotator_id => $annotator2->id,
        );
        my $updated_resource = Shachi::Service::Resource->find_by_id(
            db => $db, id => $resource->id,
        );
        is $updated_resource->annotator_id, $annotator2->id;
    };
}

sub update_status : Tests {
    my $identifier_metadata = create_metadata(name => METADATA_IDENTIFIER);

    subtest 'update normally' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        is $resource->status, STATUS_PUBLIC;

        Shachi::Service::Resource->update_status(
            db => $db, id => $resource->id, status => STATUS_PRIVATE,
        );
        my $updated_resource = Shachi::Service::Resource->find_by_id(
            db => $db, id => $resource->id,
        );
        is $updated_resource->status, STATUS_PRIVATE;
    };

    subtest 'limited_by_LDC' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        create_resource_metadata(
            resource => $resource, metadata => $identifier_metadata, content => 'LDC',
        );

        Shachi::Service::Resource->update_status(
            db => $db, id => $resource->id, status => STATUS_PUBLIC,
        );
        my $updated_resource = Shachi::Service::Resource->find_by_id(
            db => $db, id => $resource->id,
        );
        is $updated_resource->status, STATUS_LIMITED_BY_LDC;
    };

    subtest 'limited_by_ELRA' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        create_resource_metadata(
            resource => $resource, metadata => $identifier_metadata, content => 'ELRA',
        );

        Shachi::Service::Resource->update_status(
            db => $db, id => $resource->id, status => STATUS_PUBLIC,
        );
        my $updated_resource = Shachi::Service::Resource->find_by_id(
            db => $db, id => $resource->id,
        );
        is $updated_resource->status, STATUS_LIMITED_BY_ELRA;
    };

    subtest 'invalid status' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;

        dies_ok {
            Shachi::Service::Resource->update_status(
                db => $db, id => $resource->id, status => 'public_and_private',
            );
        } 'invalid status';
    };
}

sub update_edit_status : Tests {
    subtest 'update normally' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        is $resource->edit_status, EDIT_STATUS_NEW;

        Shachi::Service::Resource->update_edit_status(
            db => $db, id => $resource->id, edit_status => EDIT_STATUS_COMPLETE,
        );
        my $updated_resource = Shachi::Service::Resource->find_by_id(
            db => $db, id => $resource->id,
        );
        is $updated_resource->edit_status, EDIT_STATUS_COMPLETE;
    };

    subtest 'invalid status' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;

        dies_ok {
            Shachi::Service::Resource->update_edit_status(
                db => $db, id => $resource->id, edit_status => 'new_and_complete',
            );
        } 'invalid edit_status';
    };
}

sub delete_by_id : Tests {
    subtest 'delete normally' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        my $resource_metadata_list = [ map {
            create_resource_metadata(resource => $resource)
        } (1..3) ];

        Shachi::Service::Resource->delete_by_id(
            db => $db, id => $resource->id,
        );

        ok ! Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id), 'delete resource normally';
        my $metadata_list = Shachi::Service::Resource::Metadata->find_by_ids(
            db => $db, ids => [ map { $_->id } @$resource_metadata_list ],
        );
        is $metadata_list->size, 0;
    };

    subtest 'delete with relation' => sub {
        my $db = Shachi::Database->new;
        my $language1 = create_language;
        my $language2 = create_language;
        my $resource = create_resource;
        my $title1 = create_resource_metadata(
            resource => $resource, language => $language1,
            content => random_word, metadata_name => METADATA_TITLE,
        );
        my $title2 = create_resource_metadata(
            resource => $resource, language => $language2,
            content => random_word, metadata_name => METADATA_TITLE,
        );

        my $create_relation = sub {
            my ($resource, $language) = @_;
            create_resource_metadata(
                language => $language, metadata_name => METADATA_RELATION,
                description => $resource->relation_value
            );
        };
        $resource->title($title1->content);
        $create_relation->($resource, $language1) for (1..3);
        $resource->title($title2->content);
        $create_relation->($resource, $language2) for (1..2);
        $create_relation->($resource, $language1);

        Shachi::Service::Resource->delete_by_id(
            db => $db, id => $resource->id,
        );

        ok ! Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id), 'delete resource normally';
        is $db->shachi->table('resource_metadata')->search({
            resource_id => $resource->id
        })->count, 0;

        $resource->title($title1->content);
        is $db->shachi->table('resource_metadata')->search({
            metadata_name => METADATA_RELATION, description => $resource->relation_value,
        })->count, 0;
        $resource->title($title2->content);
        is $db->shachi->table('resource_metadata')->search({
            metadata_name => METADATA_RELATION, description => $resource->relation_value,
        })->count, 1;
        is $db->shachi->table('resource_metadata')->search({
            metadata_name => METADATA_RELATION, description => $resource->relation_value,
            language_id   => $language2->id,
        })->count, 0;
    };
}
