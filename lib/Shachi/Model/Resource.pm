package Shachi::Model::Resource;
use strict;
use warnings;
use parent qw/Shachi::Model/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id shachi_id status annotator_id edit_status/],
);

1;
