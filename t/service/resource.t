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

sub search_asia_all : Tests {
    truncate_db;
    my $resources = [ map { create_resource } (1..5) ];
    my $language_area = create_metadata(
        name => 'language_area', value_type => VALUE_TYPE_LANGUAGE_AREA,
    );
    my $asia = create_metadata_value(value_type => VALUE_TYPE_LANGUAGE_AREA, value => LANGUAGE_AREA_ASIA);
    my $japan = create_metadata_value(value_type => VALUE_TYPE_LANGUAGE_AREA, value => LANGUAGE_AREA_JAPAN);

    create_resource_metadata(resource => $resources->[1], metadata => $language_area,
                             value_id => $asia->id);
    create_resource_metadata(resource => $resources->[3], metadata => $language_area,
                             value_id => $japan->id);

    my $db = Shachi::Database->new;
    my $asia_resources = Shachi::Service::Resource->search_asia_all(db => $db);
    is_deeply $asia_resources->map('id')->to_a, [$resources->[1]->id, $resources->[3]->id];
}

sub search_titles : Tests {
    truncate_db;
    my $title_metadata = create_metadata(name => 'title');
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

sub count_not_private : Tests {
    truncate_db;
    create_resource(status => 'public');
    create_resource(status => 'private');
    create_resource(status => 'limited_by_LDC');
    create_resource(status => 'limited_by_ELRA');

    my $db = Shachi::Database->new;
    my $count = Shachi::Service::Resource->count_not_private(db => $db);
    is $count, 3;
}

sub embed_title : Tests {
    truncate_db;
    my $title_metadata = create_metadata(name => 'title');
    my $english = create_language(code => ENGLISH_CODE);

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
    my $identifier_metadata = create_metadata(name => 'identifier');

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
}
