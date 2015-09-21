package Shachi::Model;
use strict;
use warnings;
use parent qw/DBIx::Lite::Row/;
use Shachi::Model::List;

# 素のModelにするため、dataのみからオブジェクト化する
sub _new {
    my $class = shift;
    my (%params) = @_;
    bless $params{data} || {}, $class;
}

sub as_list {
    my $self = shift;
    return Shachi::Model::List->new(
        list => [ $self ]
    );
}

1;
