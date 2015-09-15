package t::Shachi::Service::Metadata::Value;
use t::test;
use String::Random qw/random_regex/;
use Shachi::Database;
use Shachi::Service::Metadata::Value;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Metadata::Value';
}

sub create : Tests {
    subtest 'create normally' => sub {
        my $db = Shachi::Database->new;
        my $value_type = random_regex('\w{8}');
        my $value = random_regex('\w{10}');

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
        my $value_type = random_regex('\w{8}');
        my $value = random_regex('\w{10}');

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
