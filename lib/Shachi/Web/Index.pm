package Shachi::Web::Index;
use strict;
use warnings;

sub default {
    my ($class, $c) = @_;
    return $c->respond_raw(200, '', 'hello world');
}

1;
