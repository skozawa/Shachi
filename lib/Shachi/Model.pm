package Shachi::Model;
use strict;
use warnings;
use parent qw/DBIx::Lite::Row/;

# 素のModelにするため、dataのみからオブジェクト化する
sub _new {
    my $class = shift;
    my (%params) = @_;
    bless $params{data} || {}, $class;
}

1;
