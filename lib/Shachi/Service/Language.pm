package Shachi::Service::Language;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::Language;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata::Value;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    $args->{code} or croak 'required code';
    $args->{name} or croak 'required name';
    $args->{area} or croak 'required area';

    my $metadata_value = Shachi::Service::Metadata::Value->find_by_value_and_value_type(
        db => $db, value_type => VALUE_TYPE_LANGUAGE, value => $args->{code},
    ) || Shachi::Service::Metadata::Value->create(db => $db, args => {
        value_type => VALUE_TYPE_LANGUAGE, value => $args->{code},
    });

    my $language = $db->shachi->table('language')->insert({
        %$args,
        value_id => $metadata_value->id,
    });
    my $last_insert_id = $db->shachi->dbh->last_insert_id(undef, undef, 'language', undef);

    Shachi::Model::Language->new(
        id => $last_insert_id,
        %$language,
    );
}

sub search_by_query {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $query => { isa => 'Str' };

    $db->shachi->table('language')->search({
        -or => [
            { code => { regexp => $query } },
            { name => { regexp => $query } }
        ]
    })->list;
}

1;
