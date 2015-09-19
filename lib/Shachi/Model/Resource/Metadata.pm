package Shachi::Model::Resource::Metadata;
use strict;
use warnings;
use parent qw/Shachi::Model/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id resource_id metadata_id language_id value_id content description/],
    rw  => [qw/value/],
);

1;
