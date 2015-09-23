package t::Shachi::Service::Resource;
use t::test;
use Shachi::Database;
use Shachi::Service::Resource;
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

sub update_status : Tests {
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
