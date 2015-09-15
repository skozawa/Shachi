package Shachi::Model::Metadata::Value;
use strict;
use warnings;
use parent qw/Shachi::Model/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id value_type value/],
);

1;
