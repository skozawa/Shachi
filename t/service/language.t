package t::Shachi::Service::Language;
use t::test;
use Shachi::Database;
use Shachi::Model::Metadata;
use Shachi::Service::Language;
use Shachi::Service::Metadata::Value;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Language';
}

sub create : Tests {
    subtest 'create normally with metadata_value' => sub {
        my $db = Shachi::Database->new;
        my $code = random_word(3);
        my $name = random_word;
        my $area = random_word;

        my $language = Shachi::Service::Language->create(db => $db, args => {
            code => $code,
            name => $name,
            area => $area,
        });

        ok $language;
        isa_ok $language, 'Shachi::Model::Language';
        is $language->code, $code, 'equal code';
        is $language->name, $name, 'equal name';
        is $language->area, $area, 'equal area';
        ok $language->id, 'has id';
        ok $language->value_id, 'has value_id';

        my $metadata_value = Shachi::Service::Metadata::Value->find_by_values(
            db => $db, value_type => VALUE_TYPE_LANGUAGE, value => $code
        );
        ok $metadata_value, 'created metadata_value';
        is $metadata_value->id, $language->value_id;
    };

    subtest 'create normally (only language)' => sub {
        my $db = Shachi::Database->new;
        my $code = random_word(3);
        my $name = random_word;
        my $area = random_word;

        my $metadata_value = Shachi::Service::Metadata::Value->create(db => $db, args => {
            value_type => 'language',
            value      => $code,
        });

        my $language = Shachi::Service::Language->create(db => $db, args => {
            code => $code,
            name => $name,
            area => $area,
        });

        ok $language;
        isa_ok $language, 'Shachi::Model::Language';
        is $language->code, $code, 'equal code';
        is $language->name, $name, 'equal name';
        is $language->area, $area, 'equal area';
        ok $language->id, 'has id';
        is $language->value_id, $metadata_value->id, 'equal value_id';
    };

    subtest 'require code, name, area' => sub {
        my $db = Shachi::Database->new;
        my $code = random_word(3);
        my $name = random_word;
        my $area = random_word;

        dies_ok {
            Shachi::Service::Metadata::Value->create(db => $db, args => {
                name => $name,
                area => $area,
            });
        } 'require code';

        dies_ok {
            Shachi::Service::Metadata::Value->create(db => $db, args => {
                code => $code,
                area => $area,
            });
        } 'require name';

        dies_ok {
            Shachi::Service::Metadata::Value->create(db => $db, args => {
                code => $code,
                name => $name,
            });
        } 'require area';
    };
}
