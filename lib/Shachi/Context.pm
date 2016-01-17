package Shachi::Context;
use strict;
use warnings;

use JSON::XS;
use URI;
use URI::QueryParam;
use Shachi::Config ();
use Shachi::Request;
use Shachi::Response;
use Shachi::View::Xslate;
use Shachi::Database;
use Shachi::Model::Language;
use Shachi::Service::Language;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/env/],
    ro_lazy => [qw/
        req res route db lang admin_lang mode
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

sub _build_mode {
    my $self = shift;
    return 'default' unless $self->route;
    return $self->route->{mode} || 'default';
}

sub _build_lang {
    my $self = shift;
    my $code = $self->req->param('ln') || $self->req->cookies->{shachi_language} || ENGLISH_CODE;
    $self->res->cookies->{shachi_language} = {
        value  => $code,
        path   => '/',
        expires => time + 24 * 60 * 60,
    };
    Shachi::Service::Language->find_by_code(db => $self->db, code => $code);
}

sub is_japanese {
    my $self = shift;
    $self->lang && $self->lang->code eq JAPANESE_CODE ? 1 : 0;
}

# 管理画面ではcookieは考慮しない
sub _build_admin_lang {
    my $self = shift;
    my $code = $self->req->param('ln') || ENGLISH_CODE;
    Shachi::Service::Language->find_by_code(db => $self->db, code => $code);
}

sub config {
    my $self = shift;
    return 'Shachi::Config' unless @_;
    return Shachi::Config->param($_[0]);
}

sub change_lang_link {
    my ($self, $lang) = @_;
    my $uri = $self->req->uri->clone;
    $uri->query_param(ln => $lang);
    $self->_to_relative_url($uri);
}

sub pager_link {
    my ($self, $offset) = @_;
    my $uri = $self->req->uri->clone;
    $uri->query_param(offset => $offset);
    $self->_to_relative_url($uri);
}

# portが引き継がれないように相対パスにする
sub _to_relative_url {
    my ($self, $uri) = @_;
    $uri->scheme(undef);
    $uri->host(undef);
    $uri->port(undef);
    my $url = $uri->as_string;
    $url =~ s!^///!/!;
    $url;
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

sub html_locale {
    my ($self, $file, $args) = @_;
    my $code = $self->lang ? $self->lang->code : 'eng';
    my $locale_file = $file;
    $locale_file =~ s/(\.html)?$/_$code$1/;
    # locale先がなければDefaultのファイル名を利用
    unless ( -r $self->config->root->file('templates', $locale_file) ) {
        $locale_file = $file;
    }
    $self->html($locale_file, $args);
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
