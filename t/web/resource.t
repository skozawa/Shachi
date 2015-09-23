package t::Shachi::Web::Resource;
use t::test;
use Shachi::Model::Metadata;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Web::Resource';
}

sub find_by_id : Tests {
    subtest 'found resource' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get_ok("/resources/@{[ $resource->id ]}");
    };

    subtest 'not found' => sub {
        my $mech = create_mech;
        $mech->get('/resources/111111111111');
        is $mech->res->code, 404;
    };
}

sub list : Tests {
    subtest 'list' => sub {
        my $mech = create_mech;
        $mech->get_ok('/resources');
    };
}

sub facet : Tests {
    subtest 'facet' => sub {
        my $mech = create_mech;
        $mech->get_ok('/resources/facet');
    };
}

sub statistics : Tests {
    truncate_db;

    subtest 'without target' => sub {
        my $mech = create_mech;
        $mech->get_ok('/resources/statistics');
    };

    subtest 'with target' => sub {
        my $mech = create_mech;
        my $metadata = create_metadata(input_type => INPUT_TYPE_SELECT);
        $mech->get_ok("/resources/statistics?target=@{[ $metadata->name ]}");
    };

    subtest 'no metadata' => sub {
        my $mech = create_mech;
        $mech->get('/resources/statistics?target=testetest');
        is $mech->res->code, 404;
    };

    subtest 'not allow' => sub {
        my $mech = create_mech;
        my $metadata = create_metadata(input_type => INPUT_TYPE_TEXT);
        $mech->get("/resources/statistics?target=@{[ $metadata->name ]}");
        is $mech->res->code, 400;
    };
}
