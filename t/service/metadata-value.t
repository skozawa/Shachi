package t::Shachi::Service::Metadata::Value;
use t::test;
use Shachi::Database;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata::Value;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Metadata::Value';
}

sub create : Tests {
    subtest 'create normally' => sub {
        my $db = Shachi::Database->new;
        my $value_type = random_word(8);
        my $value = random_word;

        my $metadata_value = Shachi::Service::Metadata::Value->create(db => $db, args => {
            value_type => $value_type,
            value      => $value,
        });

        ok $metadata_value;
        isa_ok $metadata_value, 'Shachi::Model::Metadata::Value';
        is $metadata_value->value_type, $value_type, 'equal value_type';
        is $metadata_value->value, $value, 'equal value';
        ok $metadata_value->id, 'has id';
    };

    subtest 'require value, value_type' => sub {
        my $db = Shachi::Database->new;
        my $value_type = random_word(8);
        my $value = random_word;

        dies_ok {
            Shachi::Service::Metadata::Value->create(db => $db, args => {
                value_type => $value_type,
            });
        } 'require value';

        dies_ok {
            Shachi::Service::Metadata::Value->create(db => $db, args => {
                value => $value,
            });
        } 'require value_type';
    };
}

sub find_by_value_and_value_type : Tests {
    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;
        my $value = create_metadata_value;

        cmp_deeply $value, Shachi::Service::Metadata::Value->find_by_value_and_value_type(
            db => $db, value => $value->value, value_type => $value->value_type,
        );
    };
}

sub find_by_ids : Tests {
    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;

        my $value1 = create_metadata_value;
        my $value2 = create_metadata_value;
        my $value3 = create_metadata_value;

        my $values = Shachi::Service::Metadata::Value->find_by_ids(
            db => $db, ids => [ $value1->id, $value2->id, $value3->id ],
        );

        is $values->size, 3;
    };
}

sub find_by_input_types : Tests {
    truncate_db;

    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;
        create_metadata_value(value_type => VALUE_TYPE_LANGUAGE);
        my $value = create_metadata_value(value_type => VALUE_TYPE_SPEECH_MODE);
        create_metadata_value(value_type => VALUE_TYPE_ROLE);

        my $values = Shachi::Service::Metadata::Value->find_by_value_types(
            db => $db, value_types => [ VALUE_TYPE_SPEECH_MODE ],
        );

        is $values->size, 1;
        is $values->first->id, $value->id;
    };
}
