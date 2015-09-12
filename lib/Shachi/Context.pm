package Shachi::Context;
use strict;
use warnings;

use Shachi::Config;
use Shachi::Request;
use Shachi::Response;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/env/],
    ro_lazy => [qw/
        req res route
    /],
);

sub _build_req {
    return Shachi::Request->new($_[0]->env);
}

sub _build_res {
    return Shachi::Response->new(200);
}

sub _build_route {
    return Shachi::Config->router->match($_[0]->env);
}

sub respond_raw {
    my ($self, $code, $headers, $body) = @_;
    $self->res->code($code);
    $self->res->headers($headers);
    $self->res->body($body);
}

1;
