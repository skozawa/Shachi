package t::test::factory;

use strict;
use warnings;

use lib glob '{.,t,modules/*}/lib';
use Exporter::Lite;
use String::Random qw/random_regex/;
use Shachi::Database;
use Shachi::Model::Metadata;
use Shachi::Service::Annotator;
use Shachi::Service::Language;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;
use Shachi::Service::Resource;
use Shachi::Service::Resource::Metadata;

our @EXPORT = qw/
    create_mech
    random_word
    create_annotator
    create_language
    create_metadata
    create_metadata_value
    create_resource
    create_resource_metadata

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

sub create_language {
    my (%args) = @_;

    my $code = delete $args{code} || random_word(3);
    my $name = delete $args{name} || random_word;
    my $area = delete $args{area} || random_word;

    return Shachi::Service::Language->create(db => db, args => {
        code => $code,
        name => $name,
        area => $area,
        %args,
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

sub create_resource_metadata {
    my (%args) = @_;

    my $resource = delete $args{resource} || create_resource;
    my $metadata = delete $args{metadata} || create_metadata;
    my $language = delete $args{language} || create_language;

    return Shachi::Service::Resource::Metadata->create(db => db, args => {
        resource_id => $resource->id,
        metadata_id => $metadata->id,
        language_id => $language->id,
        %args,
    });
}

sub truncate_db {
    my $tables = db->shachi->dbh->table_info('', '', '%', 'TABLE')->fetchall_arrayref({});
    db->shachi->dbh->do("truncate table `$_`") for map { $_->{TABLE_NAME} } @$tables;
}

1;
