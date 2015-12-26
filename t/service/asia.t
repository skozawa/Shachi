package t::Shachi::Service::Resource;
use t::test;
use Shachi::Database;
use Shachi::Model::Metadata;
use Shachi::Model::Metadata::Value;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Asia';
}

sub resource_ids_subquery : Tests {
    truncate_db;

    my $db = Shachi::Database->new;

    my $subquery1 = Shachi::Service::Asia->resource_ids_subquery(db => $db);
    is_deeply $subquery1, [], 'no language_area metadata';

    my $subquery2 = Shachi::Service::Asia->resource_ids_subquery(db => $db);
    is_deeply $subquery2, [], 'no asia or japan metadata value';

    my $asia = create_metadata_value(value_type => VALUE_TYPE_LANGUAGE_AREA, value => LANGUAGE_AREA_ASIA);
    my $japan = create_metadata_value(value_type => VALUE_TYPE_LANGUAGE_AREA, value => LANGUAGE_AREA_JAPAN);

    my $subquery3 = Shachi::Service::Asia->resource_ids_subquery(db => $db);
    is_deeply $subquery3, [
        "IN (SELECT resource_id FROM resource_metadata WHERE ( ( metadata_name = ? AND value_id IN ( ?, ? ) ) ))",
        METADATA_LANGUAGE_AREA, $asia->id, $japan->id,
    ];
}
