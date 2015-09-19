package Shachi::Web::List;
use strict;
use warnings;

sub default {
    my ($class, $c) = @_;
    return $c->html('list.html');
}

1;
