package Shachi::Service::Metadata;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use List::MoreUtils qw/any/;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata::Value;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    defined $args->{$_} or croak 'required ' . $_
        for qw/name label order_num input_type value_type/;

    croak 'invalid input_type'
        unless any { $args->{input_type} eq $_ } @{METADATA_INPUT_TYPES()};

    croak 'invalue value_type'
        unless $args->{value_type} && any { $args->{value_type} eq $_ } @{METADATA_VALUE_TYPES()};

    my $metadata = $db->shachi->table('metadata')->insert($args);
    my $last_insert_id = $db->shachi->dbh->last_insert_id(undef, undef, 'metadata', undef);

    Shachi::Model::Metadata->new(
        id => $last_insert_id,
        %$metadata,
    );
}

sub find_by_name {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $name  => { isa => 'Str' };

    $db->shachi->table('metadata')->search({ name => $name })->single;
}

sub find_by_names {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $names => { isa => 'ArrayRef' },
         my $args  => { isa => 'HashRef', default => {} };

    my $metadata_list = $db->shachi->table('metadata')->search({
        name  => { -in => $names },
        shown => 1,
    })->order_by('order_num asc')->list;

    if ( $args->{order_by_names} ) {
        my $index = 0;
        my %name_indices = map { $_ => $index++ } @$names;
        $metadata_list = $metadata_list->sort_by(sub { $name_indices{$_->name} });
    }

    if ( $args->{with_values} ) {
        $class->embed_metadata_values(db => $db, metadata_list => $metadata_list);
    }

    return $metadata_list;
}

sub embed_metadata_values {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $metadata_list => { isa => 'Shachi::Model::List' };

    my $values_by_type = Shachi::Service::Metadata::Value->find_by_value_types(
        db => $db, value_types => $metadata_list->map('value_type')->to_a,
    )->hash_by('value_type');
    foreach my $metadata ( @$metadata_list ) {
        my @values = $values_by_type->get_all($metadata->value_type);
        $metadata->values([ @values ]);
    }

    return $metadata_list;
}

sub find_shown_metadata {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    $db->shachi->table('metadata')->search({
        shown => 1,
    })->order_by('order_num asc')->list;
}

sub find_by_input_types {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $input_types => { isa => 'ArrayRef' };

    $db->shachi->table('metadata')->search({
        shown => 1,
        input_type => { -in => $input_types }
    })->order_by('order_num asc')->list;
}

1;
