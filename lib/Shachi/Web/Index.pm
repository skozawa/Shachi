package Shachi::Web::Index;
use strict;
use warnings;

sub default {
    my ($class, $c) = @_;
    return $c->html_locale('index.html');
}

1;
