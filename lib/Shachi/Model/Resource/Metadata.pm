package Shachi::Model::Resource::Metadata;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Shachi::Model::Metadata;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id resource_id metadata_name language_id value_id content description/],
    rw  => [qw/value/],
);

sub relation_link {
    my $self = shift;
    return unless $self->metadata_name eq METADATA_RELATION;
    return unless $self->description;
    if ( $self->description =~ /^[NCDGTO]-(\d{6}): / ) {
        return sprintf '/resources/%d', $1;
    }
}

1;
