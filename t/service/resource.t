package t::Shachi::Service::Resource;
use t::test;
use Shachi::Database;
use Shachi::Service::Resource;
use Shachi::Service::Resource::Metadata;
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
    truncate_db;
    my $english = create_language(code => 'eng');
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
            resource => $resource, metadata => $identifier_metadata,
            language => $english, content => 'LDC',
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
            resource => $resource, metadata => $identifier_metadata,
            language => $english, content => 'ELRA',
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
