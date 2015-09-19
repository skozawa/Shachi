package Shachi::Service::Metadata;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use List::MoreUtils qw/any/;
use Shachi::Model::Metadata;

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

1;
