package Shachi::Service::Resource::Metadata;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::Resource::Metadata;

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

sub shachi_id {
    args my $class => 'ClassName',
         my $resource_id,
         my $resource_subject => { optional => 1 };

    my $prefix = do {
        if ( !defined $resource_subject ) {
            'N';
        } elsif ( $resource_subject eq 'corpus' ) {
            'C';
        } elsif ( $resource_subject eq 'dictionary' ) {
            'D';
        } elsif ( $resource_subject eq 'glossary' ) {
            'G';
        } elsif ( $resource_subject eq 'thesaurus' ) {
            'T';
        } else {
            'O';
        }
    };

    return sprintf '%s-%06d', $prefix, $resource_id;
}

1;
