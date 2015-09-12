package Shachi::Context;
use strict;
use warnings;

use Shachi::Config;
use Shachi::Request;
use Shachi::Response;
use Shachi::View::Xslate;

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

sub config {
    my $self = shift;
    return 'Shachi::Config' unless @_;
    return Shachi::Config->param($_[0]);
}

## response
sub respond_raw {
    my ($self, $code, $headers, $body) = @_;
    $self->res->code($code);
    $self->res->headers($headers);
    $self->res->body($body);
}

sub html {
    my ($self, $file, $args) = @_;

    my $content = $self->render_file($file, $args);
    utf8::encode $content if utf8::is_utf8 $content;
    $self->res->code(200);
    $self->res->content_type('text/html; charset=utf-8');
    $self->res->content($content);
}

sub render_file {
    my ($self, $file, $args) = @_;
    die $self->throw_not_found unless -r $self->config->root->file('templates', $file);

    return Shachi::View::Xslate->render_file($file, {
        %{$args || {}}, c => $self,
    });
}

sub throw_not_found {
    my $self = shift;
    $self->res->code(404);
    $self->res->body('Not Found');
}

1;
