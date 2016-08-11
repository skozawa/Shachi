package t::Shachi::Model::Metadata;
use t::test;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Model::Metadata';
}

sub default_values : Tests {
    subtest 'text' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_TEXT());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => '',
            description => undef,
        };
    };

    subtest 'textarea' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_TEXTAREA());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => '',
            description => undef,
        };
    };

    subtest 'select' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_SELECT());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => undef,
            description => '',
        };
    };

    subtest 'select_only' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_SELECTONLY());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => undef,
            description => undef,
        };
    };

    subtest 'relation' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_RELATION());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => undef,
            description => '',
        };
    };

    subtest 'language' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_LANGUAGE());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => undef,
            description => '',
        };
    };

    subtest 'date' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_DATE());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => '',
            description => '',
        };
    };

    subtest 'range' => sub {
        my $metadata = create_metadata(input_type => INPUT_TYPE_RANGE());
        is_deeply $metadata->default_values, {
            value_id    => 0,
            content     => '',
            description => '',
        };
    };
}
