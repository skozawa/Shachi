package t::Shachi::Service::Resource::Metadata;
use t::test;
use Shachi::Database;
use Shachi::Model::Metadata;
use Shachi::Model::List;
use Shachi::Service::Resource::Metadata;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Resource::Metadata';
}

sub create : Tests {
    subtest 'create normally' => sub {
        my $db = Shachi::Database->new;
        my $args = {
            resource_id => int(rand(10000)),
            metadata_id => int(rand(10000)),
            language_id => int(rand(10000)),
            value_id    => int(rand(10000)),
        };

        my $resource_metadata = Shachi::Service::Resource::Metadata->create(db => $db, args => $args);

        ok $resource_metadata;
        isa_ok $resource_metadata, 'Shachi::Model::Resource::Metadata';
        is $resource_metadata->resource_id, $args->{resource_id}, 'equal resource_id';
        is $resource_metadata->metadata_id, $args->{metadata_id}, 'equal metadata_id';
        is $resource_metadata->language_id, $args->{language_id}, 'equal language_id';
        is $resource_metadata->value_id, $args->{value_id}, 'equal value_id';
        ok $resource_metadata->id, 'has id';
    };

    subtest 'require values' => sub {
        my $db = Shachi::Database->new;
        my $args = {
            resource_id => int(rand(10000)),
            metadata_id => int(rand(10000)),
            language_id => int(rand(10000)),
        };

        foreach my $key ( keys %$args ) {
            dies_ok {
                Shachi::Service::Resource::Metadata->create(db => $db, args => {
                    %$args,
                    $key => undef,
                });
            } "require $key";
        }
    };
}

sub create_multi_from_json : Tests {
    truncate_db;
    my $english = create_language(code => 'eng');
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

    subtest 'create multi normally' => sub {
        my $db = Shachi::Database->new;

        my $resource = create_resource;
        my $resource_subject_value = create_metadata_value;
        my $mono_multilingual_value = create_metadata_value;
        my $relation_value = create_metadata_value;
        my $language_value = create_language;
        my $json = {
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
        Shachi::Service::Resource::Metadata->create_multi_from_json(
            db => $db, resource_id => $resource->id, json => $json,
        );

        foreach my $key ( keys %$json ) {
            my $items = Shachi::Service::Resource::Metadata->find_resource_metadata(
                db => $db, resource => $resource,
                metadata_list => $metadata_list->{$key}->as_list,
                args => { with_value => 1 },
            );
            is $items->size, scalar @{$json->{$key}}, "$key size";
            my $first_item = $json->{$key}->[0];
            is $items->[0]->content, $first_item->{content}, "$key content" if $first_item->{content};
            is $items->[0]->description, $first_item->{description}, "$key description" if $first_item->{description};
            is $items->[0]->value_id, $first_item->{value_id}, "$key value_id" if $first_item->{value_id};
        }
    };
}

sub find_resource_metadata_by_name : Tests {
    truncate_db;
    my $title_metadata = create_metadata(name => 'title');

    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;

        my $resource1 = create_resource;
        create_resource_metadata(
            resource => $resource1, metadata => $title_metadata, content => 'test1'
        );
        my $resource2 = create_resource;
        create_resource_metadata(
            resource => $resource2, metadata => $title_metadata, content => 'test2',
        );

        my $titles = Shachi::Service::Resource::Metadata->find_resource_metadata_by_name(
            db => $db, name => 'title', resource_ids => [ $resource1->id, $resource2->id ],
        );
        $titles = $titles->sort_by(sub { $_->resource_id });
        is $titles->size, 2;
        is $titles->first->resource_id, $resource1->id;
        is $titles->first->content, 'test1';
        is $titles->last->resource_id, $resource2->id;
        is $titles->last->content, 'test2';
    };
}

sub find_resource_metadata : Tests {

    my $setup_resource = sub {
        my $resource = create_resource;
        my $metadata1 = create_metadata(value_type => VALUE_TYPE_STYLE);
        my $value1 = create_metadata_value(value_type => VALUE_TYPE_STYLE);
        create_resource_metadata(resource => $resource, metadata => $metadata1, value_id => $value1->id);
        my $metadata2 = create_metadata(value_type => VALUE_TYPE_ROLE);
        my $value2 = create_metadata_value(value_type => VALUE_TYPE_ROLE);
        create_resource_metadata(resource => $resource, metadata => $metadata2, value_id => $value2->id);
        my $metadata3 = create_metadata;
        create_resource_metadata(resource => $resource, metadata => $metadata3);

        my $metadata_list = Shachi::Model::List->new(list => [ $metadata1, $metadata2, $metadata3 ]);

        return ($resource, $metadata_list);
    };

    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;

        my ($resource, $metadata_list) = $setup_resource->();

        my $resource_metadata_list = Shachi::Service::Resource::Metadata->find_resource_metadata(
            db => $db, resource => $resource, metadata_list => $metadata_list,
        );

        is $resource_metadata_list->size, 3;
        ok ! $resource_metadata_list->any(sub { $_->value });
    };

    subtest 'find normally with value' => sub {
        my $db = Shachi::Database->new;

        my ($resource, $metadata_list) = $setup_resource->();

        my $resource_metadata_list = Shachi::Service::Resource::Metadata->find_resource_metadata(
            db => $db, resource => $resource, metadata_list => $metadata_list,
            args => { with_value => 1 },
        );

        is $resource_metadata_list->size, 3;
        ok $resource_metadata_list->any(sub { $_->value });
        is $resource_metadata_list->grep(sub { $_->value })->size, 2;
    };
}

sub statistics_by_year : Tests {
    truncate_db;

    my $issued_metadata = create_metadata(name => 'date_issued');
    my $create_resource = sub {
        my ($metadata, $value, $date) = @_;
        my $resource = create_resource;
        create_resource_metadata(
            resource => $resource, metadata => $metadata, value_id => $value->id,
        );
        create_resource_metadata(
            resource => $resource, metadata => $issued_metadata, content => $date,
        );
    };

    subtest 'statistics' => sub {
        my $db = Shachi::Database->new;

        my $metadata = create_metadata(input_type => INPUT_TYPE_SELECT);
        my $values = [ map { create_metadata_value } (1..3) ];

        #         2000 2001 2005 2015 UNK total
        # value1     1    0    2    0   1     4
        # value2     0    1    1    0   0     2
        # value3     1    0    0    1   1     3
        # total      2    1    3    1   2     9
        $create_resource->($metadata, $values->[0], '2000-01-01');
        $create_resource->($metadata, $values->[0], '2005-01-01');
        $create_resource->($metadata, $values->[0], '2005-11-01');
        $create_resource->($metadata, $values->[0], '');
        $create_resource->($metadata, $values->[1], '2001-03-01');
        $create_resource->($metadata, $values->[1], '2005-07-01');
        $create_resource->($metadata, $values->[2], '2000-05-03');
        $create_resource->($metadata, $values->[2], '2015-07-07');
        $create_resource->($metadata, $values->[2], '');

        my $statistics = Shachi::Service::Resource::Metadata->statistics_by_year(
            db => $db, metadata => $metadata,
        );

        cmp_deeply $statistics, {
            2000 => {
                $values->[0]->value => 1,
                $values->[2]->value => 1,
                total => 2,
            },
            2001 => {
                $values->[1]->value => 1,
                total => 1,
            },
            2005 => {
                $values->[0]->value => 2,
                $values->[1]->value => 1,
                total => 3,
            },
            2015 => {
                $values->[2]->value => 1,
                total => 1,
            },
            UNK => {
                $values->[0]->value => 1,
                $values->[2]->value => 1,
                total => 2,
            },
            total => {
                $values->[0]->value => 4,
                $values->[1]->value => 2,
                $values->[2]->value => 3,
                total => 9,
            },
        };
    };
}
