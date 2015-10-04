package Shachi::Request;
use strict;
use warnings;
use parent 'Plack::Request';
use JSON::XS qw/decode_json/;

sub json {
    my $self = shift;
    eval { decode_json $self->content } || {};
}

1;
