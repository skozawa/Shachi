package Shachi::Service::Resource::Metadata;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::List;
use Shachi::Model::Language;
use Shachi::Model::Metadata;
use Shachi::Model::Resource::Metadata;
use Shachi::Service::Asia;
use Shachi::Service::Language;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    $args->{$_} or croak 'required ' . $_
        for qw/resource_id metadata_name language_id/;

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
    args my $class         => 'ClassName',
         my $db            => { isa => 'Shachi::Database' },
         my $resource_id,
         my $metadata_list => { optional => 1 },
         my $json          => { isa => 'HashRef' };

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
        resource_id   => $resource_id,
        language_id   => $language->id,
        metadata_name => $metadata_list->map('name')->to_a,
    })->delete;
    $db->shachi->table('resource_metadata')->insert_multi($data) if @$data;
}

sub _create_insert_data_from_json {
    args my $db            => { isa => 'Shachi::Database' },
         my $resource_id,
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $language      => { isa => 'Shachi::Model::Language' },
         my $json          => { isa => 'HashRef' };

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
                resource_id   => $resource_id,
                metadata_name => $metadata->name,
                language_id   => $language->id,
                value_id      => $item->{value_id} || 0,
                content       => $item->{content} || '',
                description   => $item->{description} || '',
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
    args my $class        => 'ClassName',
         my $db           => { isa => 'Shachi::Database' },
         my $name         => { isa => 'Str' },
         my $resource_ids => { isa => 'ArrayRef' },
         my $language_ids => { isa => 'ArrayRef' };

    $db->shachi->table('resource_metadata')->search({
        metadata_name => $name,
        resource_id   => { -in => $resource_ids },
        language_id   => { -in => $language_ids },
    })->list;
}

sub find_resource_metadata {
    args my $class         => 'ClassName',
         my $db            => { isa => 'Shachi::Database' },
         my $resource      => { isa => 'Shachi::Model::Resource' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $language      => { isa => 'Shachi::Model::Language' },
         my $args          => { isa => 'HashRef', default => {} };

    my $language_ids = do {
        # 指定した言語のメタデータがない場合に英語にフォールバックする
        if ( $args->{fillin_english} ) {
            my $english = Shachi::Service::Language->find_by_code(db => $db, code => ENGLISH_CODE);
            [ $language->id, $english->id ];
        } else {
            [ $language->id ];
        }
    };

    my $resource_metadata_list = $db->shachi->table('resource_metadata')->search({
        resource_id   => $resource->id,
        metadata_name => { -in => $metadata_list->map('name')->to_a },
        language_id   => { -in => $language_ids },
    })->order_by('id asc')->list;

    $resource_metadata_list = $class->_exclude_multilang_values(
        language => $language, metadata_list => $metadata_list,
        resource_metadata_list => $resource_metadata_list,
    ) if $args->{fillin_english};


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

# 複数言語のメタデータがある場合は指定した言語でメタデータを絞り込む
sub _exclude_multilang_values {
    args my $class         => 'ClassName',
         my $language      => { isa => 'Shachi::Model::Language' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $resource_metadata_list => { isa => 'Shachi::Model::List' };

    # 指定した言語が最後になるようにソートする
    my $resource_metadata_by_metadata_name = $resource_metadata_list
        ->sort_by(sub { $_->language_id == $language->id })->hash_by('metadata_name');

    my $remain_ids = {};
    foreach my $metadata ( @$metadata_list ) {
        my @list = $resource_metadata_by_metadata_name->get_all($metadata->name);
        next unless @list;
        my $has_target_language_metadata = $list[-1]->language_id == $language->id;
        # 指定した言語のデータがある場合はそれのみ、ない場合は全部追加
        foreach my $item ( @list ) {
            $remain_ids->{$item->id} = 1 if !$has_target_language_metadata ||
                ($has_target_language_metadata && $item->language_id == $language->id);
        }
    }

    $resource_metadata_list->grep(sub { $remain_ids->{$_->id} });
}

sub statistics_by_year {
    args my $class    => 'ClassName',
         my $db       => { isa => 'Shachi::Database' },
         my $metadata => { isa => 'Shachi::Model::Metadata' },
         my $mode     => { isa => 'Str' };

    my $conditions = {
        metadata_name => $metadata->name,
        status => { '!=' => 'private' },
    };
    if ( $mode eq 'asia' ) {
        my $sub_query = Shachi::Service::Asia->resource_ids_subquery(db => $db);
        $conditions->{resource_id} = \$sub_query if @$sub_query;
    }
    my $resource_metadata_list = $db->shachi->table('resource_metadata')
        ->left_join('resource', { resource_id => 'id' })->search($conditions)->list;

    my $metadata_value_by_id = Shachi::Service::Metadata::Value->find_by_ids(
        db => $db, ids => $resource_metadata_list->map(sub {
            $_->value_id ? $_->value_id : ()
        })->to_a,
    )->hash_by('id');

    my $issued_by_resource_id = $db->shachi->table('resource_metadata')->search({
        metadata_name => METADATA_DATE_ISSUED,
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
