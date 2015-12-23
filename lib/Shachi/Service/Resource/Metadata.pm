package Shachi::Service::Resource::Metadata;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::List;
use Shachi::Model::Language;
use Shachi::Model::Metadata;
use Shachi::Model::Resource::Metadata;
use Shachi::Service::Language;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    $args->{$_} or croak 'required ' . $_
        for qw/resource_id metadata_id language_id/;

    my $resource_metadata = $db->shachi->table('resource_metadata')->insert($args);
    my $last_insert_id = $db->shachi->dbh->last_insert_id(undef, undef, 'resource_metadata', undef);

    Shachi::Model::Resource::Metadata->new(
        %$resource_metadata,
        id => $last_insert_id,
    );
}

sub create_multi_from_json {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $resource_id,
         my $json  => { isa => 'HashRef' };

    my $language = Shachi::Service::Language->find_by_code(
        db => $db, code => $json->{metadata_language} || ENGLISH_CODE,
    );
    my $metadata_list = Shachi::Service::Metadata->find_shown_metadata(db => $db);

    my $data = _create_insert_data_from_json(
        db => $db, resource_id => $resource_id, metadata_list => $metadata_list,
        language => $language, json => $json,
    );
    return unless @$data;

    $db->shachi->table('resource_metadata')->insert_multi($data);
}

sub update_multi_from_json {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $resource_id,
         my $metadata_list => { optional => 1 },
         my $json  => { isa => 'HashRef' };

    my $language = Shachi::Service::Language->find_by_code(
        db => $db, code => $json->{metadata_language} || ENGLISH_CODE,
    );
    $metadata_list ||= Shachi::Service::Metadata->find_by_names(
        db => $db, names => [ keys %$json ],
    );
    return unless $metadata_list && @$metadata_list;

    my $data = _create_insert_data_from_json(
        db => $db, resource_id => $resource_id, metadata_list => $metadata_list,
        language => $language, json => $json,
    );

    $db->shachi->table('resource_metadata')->search({
        resource_id => $resource_id,
        language_id => $language->id,
        metadata_id => $metadata_list->map('id')->to_a,
    })->delete;
    $db->shachi->table('resource_metadata')->insert_multi($data) if @$data;
}

sub _create_insert_data_from_json {
    args my $db   => { isa => 'Shachi::Database' },
         my $resource_id,
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $language => { isa => 'Shachi::Model::Language' },
         my $json => { isa => 'HashRef' };

    my $language_names = $metadata_list->map(sub {
        return unless $_->input_type eq INPUT_TYPE_LANGUAGE;
        my $items = $json->{$_->name} || [];
        map { $_->{content} } @$items;
    })->to_a;
    my $language_by_name = Shachi::Service::Language->search_by_names(
        db => $db, names => $language_names,
    )->hash_by('name');

    my $data = [];
    foreach my $metadata ( @$metadata_list ) {
        my $items = $json->{$metadata->name};
        next unless $items && @$items;
        foreach my $item ( @$items ) {
            # INPUT_TYPE_LANGUAGEの場合はcontentからvalue_idを補完する
            if ( $metadata->input_type eq INPUT_TYPE_LANGUAGE ) {
                my $lang = $language_by_name->{$item->{content}};
                $item->{value_id} = $lang ? $lang->value_id : 0;
            }
            push @$data, +{
                resource_id => $resource_id,
                metadata_id => $metadata->id,
                language_id => $language->id,
                value_id    => $item->{value_id} || 0,
                content     => $item->{content} || '',
                description => $item->{description} || '',
            };
        }
    }
    return $data;
}

sub find_by_ids {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $ids   => { isa => 'ArrayRef' };

    $db->shachi->table('resource_metadata')->search({
        id => { -in => $ids }
    })->list;
}

sub find_resource_metadata_by_name {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $name  => { isa => 'Str' },
         my $resource_ids => { isa => 'ArrayRef' },
         my $language_ids => { isa => 'ArrayRef' };

    my $metadata = Shachi::Service::Metadata->find_by_name(db => $db, name => $name);
    return Shachi::Model::List->new( list => [] ) unless $metadata;
    $db->shachi->table('resource_metadata')->search({
        metadata_id => $metadata->id,
        resource_id => { -in => $resource_ids },
        language_id => { -in => $language_ids },
    })->list;
}

sub find_resource_metadata {
    args my $class         => 'ClassName',
         my $db            => { isa => 'Shachi::Database' },
         my $resource      => { isa => 'Shachi::Model::Resource' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $language      => { isa => 'Shachi::Model::Language' },
         my $args          => { isa => 'HashRef', default => {} };

    my $resource_metadata_list = $db->shachi->table('resource_metadata')->search({
        resource_id => $resource->id,
        metadata_id => { -in => $metadata_list->map('id')->to_a },
        language_id => $language->id,
    })->order_by('id asc')->list;

    if ( $args->{with_value} ) {
        my $metadata_value_by_id = Shachi::Service::Metadata::Value->find_by_ids(
            db => $db, ids => $resource_metadata_list->map(sub {
                $_->value_id ? $_->value_id : ()
            })->to_a,
        )->hash_by('id');
        foreach my $resource_metadata ( @$resource_metadata_list ) {
            my $metadata_value = $metadata_value_by_id->{$resource_metadata->value_id};
            $resource_metadata->value($metadata_value);
        }
    }

    return $resource_metadata_list;
}

sub statistics_by_year {
    args my $class    => 'ClassName',
         my $db       => { isa => 'Shachi::Database' },
         my $metadata => { isa => 'Shachi::Model::Metadata' };

    my $resource_metadata_list = $db->shachi->table('resource_metadata')
        ->left_join('resource', { resource_id => 'id' })->search({
            metadata_id => $metadata->id,
            status => 'public',
        })->order_by('resource_id desc')->list;

    my $metadata_value_by_id = Shachi::Service::Metadata::Value->find_by_ids(
        db => $db, ids => $resource_metadata_list->map(sub {
            $_->value_id ? $_->value_id : ()
        })->to_a,
    )->hash_by('id');

    my $issued_metadata = Shachi::Service::Metadata->find_by_name(db => $db, name => 'date_issued');
    my $issued_by_resource_id = $db->shachi->table('resource_metadata')->search({
        metadata_id => $issued_metadata->id,
        resource_id => { -in => $resource_metadata_list->map('resource_id')->to_a },
    })->list->hash_by('resource_id');

    my $statistics = {};
    foreach my $resource_metadata ( @$resource_metadata_list ) {
        my $issued = $issued_by_resource_id->{$resource_metadata->resource_id};
        my $value  = $metadata_value_by_id->{$resource_metadata->value_id} or next;

        my $year = $issued && $issued->content ? (split/\-/, $issued->content)[0] || 'UNK' : 'UNK';
        $statistics->{$year} ||= {};
        $statistics->{$year}->{$value->value}++;
        $statistics->{$year}->{total}++;
        $statistics->{total}->{$value->value}++;
        $statistics->{total}->{total}++;
    }

    return $statistics;
}


1;
