package Shachi::Web::Index;
use strict;
use warnings;

sub default {
    my ($class, $c) = @_;
    return $c->html_locale('index.html');
}

sub about {
    my ($class, $c) = @_;
    return $c->html_locale('about.html');
}

1;
