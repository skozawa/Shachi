package t::test::factory;

use strict;
use warnings;

use lib glob '{.,t,modules/*}/lib';
use Exporter::Lite;
use String::Random qw/random_regex/;
use Shachi::Service::Annotator;
use Shachi::Service::Resource;

our @EXPORT = qw/
    create_mech
    random_word
    create_annotator
    create_resource
/;

sub db {
    Shachi::Database->new;
}

sub create_mech {
    my (%args) = @_;

    require Test::Shachi::WWW::Mechanize;
    return Test::Shachi::WWW::Mechanize->new(%args);
}

sub random_word {
    my ($num) = @_;
    random_regex('\w{' . ($num || 10) . '}');
}

sub create_annotator {
    my (%args) = @_;

    my $name = $args{name} || random_word(8);
    my $mail = $args{mail} || $name . '@test.ne.jp';
    my $org  = $args{org}  || random_word;

    return Shachi::Service::Annotator->create(db => db, args => {
        name => $name,
        mail => $mail,
        organization => $org,
    });
}

sub create_resource {
    my (%args) = @_;

    my $annotator = delete $args{annotator} || create_annotator;

    return Shachi::Service::Resource->create(db => db, args => {
        annotator_id => $annotator->id,
        %args,
    });
}

1;
