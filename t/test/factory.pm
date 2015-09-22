package t::test::factory;

use strict;
use warnings;

use lib glob '{.,t,modules/*}/lib';
use Exporter::Lite;
use String::Random qw/random_regex/;
use Shachi::Model::Metadata;
use Shachi::Service::Annotator;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;
use Shachi::Service::Resource;

our @EXPORT = qw/
    create_mech
    random_word
    create_annotator
    create_metadata
    create_metadata_value
    create_resource

    truncate_db
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

sub create_metadata {
    my (%args) = @_;

    my $name = delete $args{name} || random_word;
    my $label = delete $args{label} || random_word;
    my $order_num = delete $args{order_num} || int(rand(100));
    my $input_type = delete $args{input_type} || INPUT_TYPE_TEXT;
    my $value_type = delete $args{value_type} || '';

    return Shachi::Service::Metadata->create(db => db, args => {
        name       => $name,
        label      => $label,
        order_num  => $order_num,
        input_type => $input_type,
        value_type => $value_type,
        %args,
    });
}

sub create_metadata_value {
    my (%args) = @_;

    my $value_type = $args{value_type} || random_word;
    my $value      = $args{value} || random_word(15);

    return Shachi::Service::Metadata::Value->create(db => db, args => {
        value => $value, value_type => $value_type,
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

sub truncate_db {
    my $tables = db->shachi->dbh->table_info('', '', '%', 'TABLE')->fetchall_arrayref({});
    db->shachi->dbh->do("truncate table `$_`") for map { $_->{TABLE_NAME} } @$tables;
}

1;
