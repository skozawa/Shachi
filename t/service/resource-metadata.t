package t::Shachi::Service::Resource::Metadata;
use t::test;
use String::Random qw/random_regex/;
use Shachi::Database;
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
