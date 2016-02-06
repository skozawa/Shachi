package t::test::factory;

use strict;
use warnings;

use lib glob '{.,t,modules/*}/lib';
use Exporter::Lite;
use String::Random qw/random_regex/;
use Hash::MultiValue;
use Shachi::Database;
use Shachi::Model::Language;
use Shachi::Model::Metadata;
use Shachi::Model::Metadata::Value;
use Shachi::FacetSearchQuery;
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
    set_language_area
    set_asia
    get_english
    create_facet_search_query

    truncate_db_with_setup
    setup
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

    my $name = delete $args{name} || random_word(30);
    my $label = delete $args{label} || random_word;
    my $order_num = delete $args{order_num} || int(rand(100));
    my $input_type = delete $args{input_type} || INPUT_TYPE_TEXT;
    my $value_type = delete $args{value_type} || '';

    return Shachi::Service::Metadata->find_by_name(db => db, name => $name) ||
        Shachi::Service::Metadata->create(db => db, args => {
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
        metadata_name => $metadata->name,
        language_id => $language->id,
        %args,
    });
}

sub set_language_area {
    my ($resource, $language_area_value, $language) = @_;
    my $language_area = Shachi::Service::Metadata->find_by_name(
        db => db, name => METADATA_LANGUAGE_AREA
    ) || create_metadata(
        name       => METADATA_LANGUAGE_AREA,
        value_type => VALUE_TYPE_LANGUAGE_AREA,
        input_type => INPUT_TYPE_SELECT
    );
    my $value = Shachi::Service::Metadata::Value->find_by_values_and_value_type(
        db => db, value_type => VALUE_TYPE_LANGUAGE_AREA, values => [$language_area_value],
    )->first || create_metadata_value(
        value_type => VALUE_TYPE_LANGUAGE_AREA,
        value      => $language_area_value
    );
    create_resource_metadata(
        resource => $resource, metadata => $language_area, value_id => $value->id,
        $language ? (language => $language) : (),
    );
}

sub set_asia {
    my ($resource, $language) = @_;
    set_language_area($resource, LANGUAGE_AREA_ASIA, $language);
}

sub get_english {
    Shachi::Service::Language->find_by_code(db => db, code => ENGLISH_CODE)
            || create_language(code => ENGLISH_CODE);
}

sub create_facet_search_query {
    my $params = Hash::MultiValue->new;
    $params->add($_->[0], $_->[1]) for @_;
    Shachi::FacetSearchQuery->new(params => $params);
}

sub truncate_db_with_setup {
    truncate_db();
    setup();
}

# テストに必要なデータを用意しておく
sub setup {
    get_english();
}

sub truncate_db {
    my $tables = db->shachi->dbh->table_info('', '', '%', 'TABLE')->fetchall_arrayref({});
    db->shachi->dbh->do("truncate table `$_`") for map { $_->{TABLE_NAME} } @$tables;
}

1;
