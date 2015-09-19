package Shachi::Service::Resource::Metadata;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::Resource::Metadata;
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


sub find_resource_titles {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $resource_ids => { isa => 'ArrayRef' };

    my $title_metadata = Shachi::Service::Metadata->find_by_name(db => $db, name => 'title');
    $db->shachi->table('resource_metadata')->search({
        metadata_id => $title_metadata->id,
        resource_id => { -in => $resource_ids },
    })->list;
}

sub find_resource_metadata {
    args my $class         => 'ClassName',
         my $db            => { isa => 'Shachi::Database' },
         my $resource      => { isa => 'Shachi::Model::Resource' },
         my $metadata_list => { isa => 'Shachi::Model::List' },
         my $args          => { isa => 'HashRef', default => {} };

    my $resource_metadata_list = $db->shachi->table('resource_metadata')->search({
        resource_id => $resource->id,
        metadata_id => { -in => $metadata_list->map('id')->to_a }
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

    my $resource_metadata_list = $db->shachi->table('resource_metadata')->search({
        metadata_id => $metadata->id,
    })->list;

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
