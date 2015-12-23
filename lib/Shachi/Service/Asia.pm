package Shachi::Service::Asia;
use strict;
use warnings;
use Smart::Args;
use SQL::Abstract;
use Shachi::Model::Metadata;
use Shachi::Model::Metadata::Value;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;

sub resource_ids_subquery {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    my $language_area = Shachi::Service::Metadata->find_by_name(
        db => $db, name => METADATA_LANGUAGE_AREA
    );
    return [] unless $language_area;
    my $asia_and_japan = Shachi::Service::Metadata::Value->find_by_values_and_value_type(
        db => $db, value_type => $language_area->value_type,
        values => [LANGUAGE_AREA_ASIA, LANGUAGE_AREA_JAPAN],
    );
    return [] unless $asia_and_japan->size;

    my $sql = SQL::Abstract->new;
    my ($sub_sql, @sub_bind) = $sql->select('resource_metadata', 'resource_id', {
        metadata_id => $language_area->id,
        value_id    => { -in => $asia_and_japan->map('id')->to_a },
    });
    return ["IN ($sub_sql)" => @sub_bind];
}

1;
