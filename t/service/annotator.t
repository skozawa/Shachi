package t::Shachi::Service::Annotator;
use t::test;
use String::Random qw/random_regex/;
use Shachi::Database;
use Shachi::Model::Annotator;
use Shachi::Service::Annotator;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::Annotator';
}

sub create : Tests {
    subtest '正常に作成できる' => sub {
        my $db = Shachi::Database->new;
        my $name = random_regex('\w{8}');
        my $mail = $name . '@test.ne.jp';
        my $org  = random_regex('\w{10}');

        my $annotator = Shachi::Service::Annotator->create($db, {
            name => $name,
            mail => $mail,
            organization => $org,
        });

        ok $annotator;
        isa_ok $annotator, 'Shachi::Model::Annotator';
        is $annotator->name, $name;
        is $annotator->mail, $mail;
        is $annotator->organization, $org;
        ok $annotator->id;
    };
}
