package Shachi::Model::Annotator;
use strict;
use warnings;
use parent qw/Shachi::Model/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id name mail organization/],
    rw  => [qw/resources resource_count/],
);

1;
