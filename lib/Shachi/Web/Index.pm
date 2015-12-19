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

sub publications {
    my ($class, $c) = @_;
    return $c->html_locale('publications.html');
}

sub news {
    my ($class, $c) = @_;
    return $c->html_locale('news.html');
}

1;
