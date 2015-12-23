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

    my $metadata_value = Shachi::Service::Metadata::Value->find_by_values_and_value_type(
        db => $db, value_type => VALUE_TYPE_LANGUAGE, values => [$args->{name}],
    )->first || Shachi::Service::Metadata::Value->create(db => $db, args => {
        value_type => VALUE_TYPE_LANGUAGE, value => $args->{name},
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

sub find_by_code {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $code  => { isa => 'Str' };

    $db->shachi->table('language')->search({ code => $code })->single;
}

sub search_by_names {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $names => { isa => 'ArrayRef' };

    $db->shachi->table('language')->search({
        name => { -in => $names }
    })->list;
}

sub search_by_query {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $query => { isa => 'Str' };

    $db->shachi->table('language')->search({
        -or => [
            { code => { regexp => $query } },
            { 'name COLLATE utf8mb4_unicode_ci' => { regexp => $query } }
        ],
    })->order_by('code asc')->list;
}

1;
