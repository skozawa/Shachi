package t::Shachi::Service::Annotator;
use t::test;
use Shachi::Database;
use Shachi::Service::Annotator;
use Shachi::Model::List;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Annotator';
}

sub create : Tests {
    subtest 'create normally' => sub {
        my $db = Shachi::Database->new;
        my $name = random_word(8);
        my $mail = $name . '@test.ne.jp';
        my $org  = random_word;

        my $annotator = Shachi::Service::Annotator->create(db => $db, args => {
            name => $name,
            mail => $mail,
            organization => $org,
        });

        ok $annotator;
        isa_ok $annotator, 'Shachi::Model::Annotator';
        is $annotator->name, $name, 'equal name';
        is $annotator->mail, $mail, 'equal mail';
        is $annotator->organization, $org, 'equal organization';
        ok $annotator->id, 'has id';
    };

    subtest 'require name, mail, organization' => sub {
        my $db = Shachi::Database->new;
        my $name = random_word(8);
        my $mail = $name . '@test.ne.jp';
        my $org  = random_word;

        dies_ok {
            Shachi::Service::Annotator->create(db => $db, args => {
                mail => $mail,
                organization => $org,
            });
        } 'require name';

        dies_ok {
            Shachi::Service::Annotator->create(db => $db, args => {
                name => $name,
                organization => $org,
            });
        } 'require mail';

        dies_ok {
            Shachi::Service::Annotator->create(db => $db, args => {
                name => $name,
                mail => $mail,
            });
        } 'require organization';
    };
}

sub find_by_id : Tests {
    subtest 'find normally' => sub {
        my $db = Shachi::Database->new;
        my $annotator = create_annotator;

        cmp_deeply $annotator, Shachi::Service::Annotator->find_by_id(
            db => $db, id => $annotator->id
        );
    };
}

sub embed_resources : Tests {
    subtest 'embed normally' => sub {
        my $db = Shachi::Database->new;
        my $annotator = create_annotator;
        my $language  = create_language;
        my $resources = [ map { create_resource(annotator => $annotator) } (1..3) ];

        Shachi::Service::Annotator->embed_resources(
            db => $db, annotators => $annotator->as_list, language => $language,
        );

        ok $annotator->resources;
        is $annotator->resources->size, 3;
        is_deeply $annotator->resources->map('id')->to_a, [ map {
            $_->id
        } @$resources ];
    };
}

sub embed_resource_count : Tests {
    subtest 'embed normally' => sub {
        my $db = Shachi::Database->new;
        my $annotator1 = create_annotator;
        create_resource(annotator => $annotator1) for (1..2);
        my $annotator2 = create_annotator;
        create_resource(annotator => $annotator2) for (1..3);

        Shachi::Service::Annotator->embed_resource_count(
            db => $db,
            annotators => Shachi::Model::List->new(list => [ $annotator1, $annotator2 ]),
        );

        is $annotator1->resource_count, 2;
        is $annotator2->resource_count, 3;
    };
}
