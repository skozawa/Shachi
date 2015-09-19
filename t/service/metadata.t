package t::Shachi::Service::Metadata;
use t::test;
use String::Random qw/random_regex/;
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
            name  => random_regex('\w{10}'),
            label => random_regex('\w{10}'),
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
            name  => random_regex('\w{10}'),
            label => random_regex('\w{10}'),
            order_num => int(rand(100)),
            value_type => VALUE_TYPE_LANGUAGE,
        };

        dies_ok {
            Shachi::Service::Metadata->create(db => $db, args => {
                %$values,
                input_type => random_regex('\w{10}'),
            });
        } "invalid input_type";
    };

    subtest 'invalid value_type' => sub {
        my $db = Shachi::Database->new;
        my $values = {
            name  => random_regex('\w{10}'),
            label => random_regex('\w{10}'),
            order_num => int(rand(100)),
            input_type => INPUT_TYPE_TEXT,
        };

        dies_ok {
            Shachi::Service::Metadata->create(db => $db, args => {
                %$values,
                value_type => random_regex('\w{10}'),
            });
        } "invalid value_type";
    };

    subtest 'require values' => sub {
        my $db = Shachi::Database->new;
        my $values = {
            name  => random_regex('\w{10}'),
            label => random_regex('\w{10}'),
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
