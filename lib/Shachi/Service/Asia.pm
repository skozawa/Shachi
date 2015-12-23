package Shachi::Service::Asia;
use strict;
use warnings;
use Smart::Args;
use SQL::Abstract;
use Shachi::Model::Metadata;
use Shachi::Model::Metadata::Value;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;

sub langauge_area {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };
    Shachi::Service::Metadata->find_by_name(
        db => $db, name => METADATA_LANGUAGE_AREA,
    );
}

sub area_values {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };
    Shachi::Service::Metadata::Value->find_by_values_and_value_type(
        db => $db, value_type => VALUE_TYPE_LANGUAGE_AREA,
        values => [ LANGUAGE_AREA_ASIA, LANGUAGE_AREA_JAPAN ],
    );
}

sub resource_ids_subquery {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    my $language_area = $class->langauge_area(db => $db) or return [];
    my $asia_and_japan = $class->area_values(db => $db);
    return [] unless $asia_and_japan->size;

    my $sql = SQL::Abstract->new;
    my ($sub_sql, @sub_bind) = $sql->select('resource_metadata', 'resource_id', {
        metadata_id => $language_area->id,
        value_id    => { -in => $asia_and_japan->map('id')->to_a },
    });
    return ["IN ($sub_sql)" => @sub_bind];
}

sub resource_resultset {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    my $language_area = $class->langauge_area(db => $db) or return;
    my $values = $class->area_values(db => $db);
    return unless $values->size;

    $db->shachi->table('resource')
        ->left_join('resource_metadata', { id => 'resource_id' })->search({
            metadata_id => $language_area->id,
            value_id    => { -in => $values->map('id')->to_a },
        });
}

1;
