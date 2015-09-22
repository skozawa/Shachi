package t::Shachi::Service::Metadata;
use t::test;
use Shachi::Database;
use Shachi::Service::Metadata;
use Shachi::Model::Metadata;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Metadata';
}

sub create : Tests {
    subtest 'create normally' => sub {
        my $db = Shachi::Database->new;
        my $values = {
            name  => random_word,
            label => random_word,
            order_num => int(rand(100)),
            input_type => INPUT_TYPE_LANGUAGE,
            value_type => VALUE_TYPE_LANGUAGE,
        };

        my $metadata = Shachi::Service::Metadata->create(db => $db, args => $values);

        ok $metadata;
        isa_ok $metadata, 'Shachi::Model::Metadata';
        is $metadata->name, $values->{name}, 'equal name';
        is $metadata->label, $values->{label}, 'equal label';
        is $metadata->order_num, $values->{order_num}, 'equal order_num';
        is $metadata->input_type, $values->{input_type}, 'equal input_type';
        is $metadata->value_type, $values->{value_type}, 'equal value_type';
        ok $metadata->id, 'has id';
    };

    subtest 'invalid input_type' => sub {
        my $db = Shachi::Database->new;
        my $values = {
            name  => random_word,
            label => random_word,
            order_num => int(rand(100)),
            value_type => VALUE_TYPE_LANGUAGE,
        };

        dies_ok {
            Shachi::Service::Metadata->create(db => $db, args => {
                %$values,
                input_type => random_word,
            });
        } "invalid input_type";
    };

    subtest 'invalid value_type' => sub {
        my $db = Shachi::Database->new;
        my $values = {
            name  => random_word,
            label => random_word,
            order_num => int(rand(100)),
            input_type => INPUT_TYPE_TEXT,
        };

        dies_ok {
            Shachi::Service::Metadata->create(db => $db, args => {
                %$values,
                value_type => random_word,
            });
        } "invalid value_type";
    };

    subtest 'require values' => sub {
        my $db = Shachi::Database->new;
        my $values = {
            name  => random_word,
            label => random_word,
            order_num => int(rand(100)),
            input_type => INPUT_TYPE_LANGUAGE,
            value_type => VALUE_TYPE_LANGUAGE,
        };

        foreach my $key ( keys %$values ) {
            dies_ok {
                Shachi::Service::Metadata->create(db => $db, args => {
                    %$values,
                    $key => undef,
                });
            } "require $key";
        }
    };
}

sub find_by_name : Tests {
    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;
        my $name = random_word(15);
        my $metadata = create_metadata(name => $name);

        my $found_metadata = Shachi::Service::Metadata->find_by_name(
            db => $db, name => $name,
        );
        is $metadata->id, $found_metadata->id;
    };
}

sub find_by_names : Tests {
    subtest 'find normally (sort by order_num)' => sub {
        my $db = Shachi::Database->new;
        my $metadata1 = create_metadata(order_num => 3);
        my $metadata2 = create_metadata(order_num => 5);
        my $metadata3 = create_metadata(order_num => 7);

        my $metadata_list = Shachi::Service::Metadata->find_by_names(
            db => $db, names => [ $metadata1->name, $metadata2->name ],
        );

        is $metadata_list->size, 2;
        cmp_deeply $metadata_list->map('id')->to_a, [ $metadata1->id, $metadata2->id ];
    };

    subtest 'find normaly sorted by names' => sub {
        my $db = Shachi::Database->new;
        my $metadata1 = create_metadata(order_num => 3);
        my $metadata2 = create_metadata(order_num => 5);
        my $metadata3 = create_metadata(order_num => 7);

        my $metadata_list = Shachi::Service::Metadata->find_by_names(
            db => $db, names => [ $metadata2->name, $metadata1->name, $metadata3->name ],
            args => { order_by_names => 1 },
        );

        is $metadata_list->size, 3;
        cmp_deeply $metadata_list->map('id')->to_a, [ $metadata2->id, $metadata1->id, $metadata3->id];
    };
}

sub embed_metadata_values : Tests {
    truncate_db;

    subtest 'embed normally' => sub {
        my $db = Shachi::Database->new;
        my $metadata = create_metadata(
            input_type => INPUT_TYPE_SELECT,
            value_type => VALUE_TYPE_SPEECHMODE,
        );
        my $metadata_values = [ map {
            create_metadata_value(value_type => VALUE_TYPE_SPEECHMODE)
        } (1..5) ];

        Shachi::Service::Metadata->embed_metadata_values(
            db => $db, metadata_list => $metadata->as_list,
        );

        ok $metadata->values;
        is $metadata->values->size, 5;
    };
}

sub find_shown_metadata : Tests {
    truncate_db;

    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;
        create_metadata for (1..3);
        create_metadata(shown => 0);

        my $metadata_list = Shachi::Service::Metadata->find_shown_metadata(db => $db);

        is $metadata_list->size, 3;
        ok ! $metadata_list->any(sub { !$_->shown });
    };
}

sub find_by_input_types : Tests {
    truncate_db;

    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;
        create_metadata(input_type => INPUT_TYPE_TEXT);
        my $metadata = create_metadata(input_type => INPUT_TYPE_SELECT);
        create_metadata(input_type => INPUT_TYPE_LANGUAGE);

        my $metadata_list = Shachi::Service::Metadata->find_by_input_types(
            db => $db, input_types => [ INPUT_TYPE_SELECT ],
        );

        is $metadata_list->size, 1;
        is $metadata_list->first->id, $metadata->id;
    };
}
