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

1;
