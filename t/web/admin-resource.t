package t::Shachi::Web::Admin::Resource;
use t::test;
use JSON::XS;
use Shachi::Database;
use Shachi::Model::Language;
use Shachi::Model::Resource;
use Shachi::Model::Metadata;
use Shachi::Service::Resource;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Web::Admin::Resource';
}

sub create_get : Tests {
    my $mech = create_mech;
    $mech->get_ok('/admin/resources/create');
}

sub create_post : Tests {
    truncate_db_with_setup;

    my $metadata_list = +{ map {
        $_->[0] => create_metadata(name => $_->[0], input_type => $_->[1])
    } (['title', INPUT_TYPE_TEXT],
     ['description', INPUT_TYPE_TEXTAREA],
     ['subject_resourceSubject', INPUT_TYPE_SELECT],
     ['subject_monoMultilingual', INPUT_TYPE_SELECTONLY],
     ['relation', INPUT_TYPE_RELATION],
     ['language', INPUT_TYPE_LANGUAGE],
     ['date_issued', INPUT_TYPE_DATE],
     ['date_created', INPUT_TYPE_RANGE],
    ) };

    subtest 'create normally' => sub {
        my $mech = create_mech;
        my $annotator = create_annotator;
        my $resource_subject_value = create_metadata_value(value => 'corpus');
        my $mono_multilingual_value = create_metadata_value;
        my $relation_value = create_metadata_value;
        my $language_value = create_language;
        my $json = {
            annotator_id => $annotator->id,
            status => 'public',
            title => [ { content => 'test corpus' } ],
            description => [ { content => 'test test' } ],
            subject_resourceSubject => [
                { value_id => $resource_subject_value->id, description => '' },
                { value_id => '', description => 'test' },
            ],
            subject_monoMultilingual => [
                { value_id => $mono_multilingual_value->id },
            ],
            relation => [
                { value_id => $relation_value->id, description => 'test relation' },
            ],
            language => [
                { content => $language_value->name, description => 'test language' },
            ],
            date_issued => [ { content => '2015-10-01' } ],
            date_created => [
                { content => '2014-01-01 2015-08-01', description => 'test created' }
            ],
        };

        $mech->post('/admin/resources/create', Content => encode_json $json);
        is $mech->res->code, 200;

        my $res_json = decode_json($mech->res->content);
        my $resource_id = $res_json->{resource_id};
        my $db = Shachi::Database->new;
        my $resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource_id);
        ok $resource;
        is $resource->shachi_id, 'C-000001';
    };
}

sub delete : Tests {
    subtest 'delete normally by delete' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        my $mech = create_mech;

        $mech->delete("/admin/resources/@{[ $resource->id ]}");
        is $mech->res->code, 200;
        my $res_json = decode_json($mech->res->content);
        ok $res_json->{success};

        my $deleted_resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id);
        ok ! $deleted_resource;
    };

    subtest 'delete normally' => sub {
        my $db = Shachi::Database->new;
        my $resource = create_resource;
        my $mech = create_mech;

        $mech->post("/admin/resources/@{[ $resource->id ]}/delete");
        is $mech->res->code, 200;

        my $deleted_resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id);
        ok ! $deleted_resource;
    };
}

sub update_annotator : Tests {
    subtest 'update normally' => sub {
        my $annotator = create_annotator;
        my $resource = create_resource;
        my $mech = create_mech;

        $mech->post("/admin/resources/@{[ $resource->id ]}/annotator", {
            annotator_id => $annotator->id,
        });
        my $res_json = decode_json($mech->res->content);
        is $res_json->{annotator}->{id}, $annotator->id;
        is $res_json->{annotator}->{name}, $annotator->name;
    };
}

sub update_status : Tests {
    subtest 'update normally' => sub {
        my $resource = create_resource;
        my $mech = create_mech;

        $mech->post("/admin/resources/@{[ $resource->id ]}/status", {
            status => STATUS_PRIVATE,
        });
        my $res_json = decode_json($mech->res->content);
        is $res_json->{status}, STATUS_PRIVATE;

        my $db = Shachi::Database->new;
        my $updated_resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id);
        is $updated_resource->status, STATUS_PRIVATE;
    };
}

sub update_edit_status : Tests {
    subtest 'update normally' => sub {
        my $resource = create_resource;
        my $mech = create_mech;

        $mech->post("/admin/resources/@{[ $resource->id ]}/edit_status", {
            edit_status => EDIT_STATUS_COMPLETE,
        });
        my $res_json = decode_json($mech->res->content);
        is $res_json->{edit_status}, EDIT_STATUS_COMPLETE;

        my $db = Shachi::Database->new;
        my $updated_resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id);
        is $updated_resource->edit_status, EDIT_STATUS_COMPLETE;
    };
}

sub update_metadata : Tests {
    truncate_db;
    my $language = create_language;
    my $metadata_list = +{ map {
        $_->[0] => create_metadata(name => $_->[0], input_type => $_->[1])
    } ([METADATA_TITLE, INPUT_TYPE_TEXT],
     [METADATA_SUBJECT_RESOURCE_SUBJECT, INPUT_TYPE_SELECT],
     ['language', INPUT_TYPE_LANGUAGE],
     [METADATA_RELATION, INPUT_TYPE_RELATION],
    ) };

    subtest 'update title and language' => sub {
        my $mech = create_mech;
        my $resource = create_resource;
        $resource->title(random_word);
        create_resource_metadata(
            resource => $resource,
            metadata => $metadata_list->{title},
            language => $language,
            content  => $resource->title,
        );
        create_resource_metadata(
            resource => $resource,
            metadata => $metadata_list->{language},
            language => $language,
        );
        # create relation
        create_resource_metadata(
            language => $language, metadata => $metadata_list->{relation},
            description => $resource->relation_value,
        ) for (1..3);

        my $language_value = create_language;
        my $new_title = random_word;
        my $json = {
            title => [ { content => $new_title } ],
            language => [
                { content => $language_value->name, description => 'test language' },
            ],
            metadata_language => $language->code,
        };

        $mech->post("/admin/resources/@{[ $resource->id ]}/metadata", Content => encode_json $json);
        is $mech->res->code, 200;

        my $res_json = decode_json($mech->res->content);
        is $res_json->{resource_id}, $resource->id;
        is $res_json->{title}->[0]->{content}, $new_title;
        is $res_json->{language}->[0]->{value}, $language_value->name;

        $resource->title($new_title);
        my $db = Shachi::Database->new;
        is $db->shachi->table('resource_metadata')->search({
            metadata_name => METADATA_RELATION, language_id => $language->id,
            description => $resource->relation_value
        })->count, 3;
    };

    subtest 'update resource subject' => sub {
        my $mech = create_mech;
        my $resource = create_resource;
        create_resource_metadata(
            resource => $resource, metadata => $metadata_list->{relation},
            language => $language, description => $resource->relation_value
        ) for (1..2);
        my $resource_subject_value = create_metadata_value(value => 'corpus');
        my $json = {
            subject_resourceSubject => [
                { value_id => $resource_subject_value->id, description => '' },
                { value_id => '', description => 'test' },
            ],
            metadata_language => $language->code,
        };

        $mech->post("/admin/resources/@{[ $resource->id ]}/metadata", Content => encode_json $json);
        is $mech->res->code, 200;

        my $res_json = decode_json($mech->res->content);
        is $res_json->{resource_id}, $resource->id;
        is $res_json->{subject_resourceSubject}->[0]->{value_id}, $resource_subject_value->id;
        is $res_json->{subject_resourceSubject}->[1]->{description}, 'test';
        my $db = Shachi::Database->new;
        my $resource = Shachi::Service::Resource->find_by_id(db => $db, id => $resource->id);
        ok $resource;
        is $resource->shachi_id, sprintf('C-%06d', $resource->id);

        is $db->shachi->table('resource_metadata')->search({
            metadata_name => METADATA_RELATION, language_id => $language->id,
            description => $resource->relation_value,
        })->count, 2;
    };
}
