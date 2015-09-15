package t::Shachi::Service::Annotator;
use t::test;
use String::Random qw/random_regex/;
use Shachi::Database;
use Shachi::Service::Annotator;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Annotator';
}

sub create : Tests {
    subtest 'create normally' => sub {
        my $db = Shachi::Database->new;
        my $name = random_regex('\w{8}');
        my $mail = $name . '@test.ne.jp';
        my $org  = random_regex('\w{10}');

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
        my $name = random_regex('\w{8}');
        my $mail = $name . '@test.ne.jp';
        my $org  = random_regex('\w{10}');

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
