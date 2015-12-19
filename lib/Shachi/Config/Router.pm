package Shachi::Config::Router;
use strict;
use warnings;
use Router::Simple::Declare qw(connect);

my $router = Router::Simple::Declare::router {
    connect '/' => {
        dispatch => 'Shachi::Web::Index',
    };
    connect '/about' => {
        dispatch => 'Shachi::Web::Index',
        action   => 'about',
    };
    connect '/publications' => {
        dispatch => 'Shachi::Web::Index',
        action   => 'publications',
    };
    connect '/news' => {
        dispatch => 'Shachi::Web::Index',
        action   => 'news',
    };

    connect '/resources' => {
        dispatch => 'Shachi::Web::Resource',
        action   => 'list',
    };
    connect "/resources/{resource_id:[0-9]+}" => {
        dispatch => 'Shachi::Web::Resource',
        action   => 'find_by_id',
    };
    connect '/resources/facet' => {
        dispatch => 'Shachi::Web::Resource',
        action   => 'facet',
    };
    connect '/resources/statistics' => {
        dispatch => 'Shachi::Web::Resource',
        action   => 'statistics',
    };

    connect '/admin/' => {
        dispatch => 'Shachi::Web::Admin',
    };
    connect '/admin/languages/search' => {
        dispatch => 'Shachi::Web::Admin::Language',
        action   => 'search',
    };
    connect '/admin/resources/create' => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'create_get'
    }, { method => 'GET' };
    connect '/admin/resources/create' => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'create_post'
    }, { method => 'POST' };
    connect '/admin/resources/search' => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'search'
    };
    connect "/admin/resources/{resource_id:[0-9]+}" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'find_by_id',
    }, { method => 'GET' };
    connect "/admin/resources/{resource_id:[0-9]+}" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'delete',
    }, { method => 'DELETE' };
    connect "/admin/resources/{resource_id:[0-9]+}/delete" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'delete',
    }, { method => 'POST' };
    connect "/admin/resources/{resource_id:[0-9]+}/annotator" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'update_annotator',
    }, { method => 'POST' };
    connect "/admin/resources/{resource_id:[0-9]+}/status" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'update_status',
    }, { method => 'POST' };
    connect "/admin/resources/{resource_id:[0-9]+}/edit_status" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'update_edit_status',
    }, { method => 'POST' };
    connect "/admin/resources/{resource_id:[0-9]+}/metadata" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'update_metadata',
    }, { method => 'POST' };
};

sub router { $router }

1;
