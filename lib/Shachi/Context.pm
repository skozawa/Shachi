package Shachi::Context;
use strict;
use warnings;

use JSON::XS;
use Shachi::Config ();
use Shachi::Request;
use Shachi::Response;
use Shachi::View::Xslate;
use Shachi::Database;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/env/],
    ro_lazy => [qw/
        req res route db
    /],
    rw_lazy => [qw/page_id/],
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

sub _build_db {
    return Shachi::Database->new;
}

sub _build_page_id {
    my $self = shift;
    return undef unless $self->route;
    return $self->route->{page_id} if $self->route->{page_id};

    my ($engine) = $self->route->{dispatch} =~ /^Shachi::Web::(\S+)/ or return undef;
    my $page_id = join '-', map lc, split /::/, $engine;
    if (my $action = $self->route->{action}) {
        $page_id .= "-$action" if $action ne 'default';
    }
    return $page_id;
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

sub json {
    my ($self, $res) = @_;
    $self->res->code(200);
    $self->res->content_type('application/json; charset=utf-8');
    $self->res->content(encode_json($res));
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

sub redirect {
    my ($self, $url) = @_;
    $self->res->code(302);
    $self->res->header( Location => $url );
}

sub throw_bad_request {
    my $self = shift;
    $self->res->code(400);
    $self->res->body('Bad Request');
}

sub throw_not_found {
    my $self = shift;
    $self->res->code(404);
    $self->res->body('Not Found');
}

1;
