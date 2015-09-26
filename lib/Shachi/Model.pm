package Shachi::Model;
use strict;
use warnings;
use parent qw/DBIx::Lite::Row/;
use Shachi::Model::List;
use DateTime::Format::MySQL;

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

sub _from_db_timestamp {
    my ($self, $timestamp) = @_;
    return if !defined $timestamp || $timestamp eq '0000-00-00 00:00:00';
    my $dt = eval { DateTime::Format::MySQL->parse_datetime($timestamp) } or return;
    $dt->set_time_zone('Asia/Tokyo');
    return $dt;
}

1;
