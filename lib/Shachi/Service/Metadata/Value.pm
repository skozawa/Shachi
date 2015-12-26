package Shachi::Service::Metadata::Value;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::Metadata::Value;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    $args->{value_type} or croak 'required value_type';
    $args->{value} or croak 'required value';

    my $metadata_value = $db->shachi->table('metadata_value')->insert($args);
    my $last_insert_id = $db->shachi->dbh->last_insert_id(undef, undef, 'metadata_value', undef);

    Shachi::Model::Metadata::Value->new(
        id => $last_insert_id,
        %$metadata_value,
    );
}

sub find_by_values_and_value_type {
    args my $class      => 'ClassName',
         my $db         => { isa => 'Shachi::Database' },
         my $value_type => { isa => 'Str' },
         my $values     => { isa => 'ArrayRef' };

    $db->shachi->table('metadata_value')->search({
        value_type => $value_type,
        value      => { -in => $values },
    })->list;
}

sub find_by_id {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id;
    $db->shachi->table('metadata_value')->search({ id => $id })->single;
}

sub find_by_ids {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $ids   => { isa => 'ArrayRef' },
         my $order => { default => 'id asc' };
    $db->shachi->table('metadata_value')->search({ id => { -in => $ids } })
        ->order_by($order)->list;
}

sub find_by_value_types {
    args my $class       => 'ClassName',
         my $db          => { isa => 'Shachi::Database' },
         my $value_types => { isa => 'ArrayRef' };

    $db->shachi->table('metadata_value')->search({
        value_type => { -in => $value_types }
    })->list;
}

1;
