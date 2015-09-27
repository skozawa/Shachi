package Shachi::Config::Router;
use strict;
use warnings;
use Router::Simple::Declare qw(connect);

my $router = Router::Simple::Declare::router {
    connect '/' => {
        dispatch => 'Shachi::Web::Index',
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
    connect "/admin/resources/{resource_id:[0-9]+}" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'find_by_id',
    };
    connect "/admin/resources/{resource_id:[0-9]+}/status" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'update_status',
    }, { method => 'POST' };
    connect "/admin/resources/{resource_id:[0-9]+}/edit_status" => {
        dispatch => 'Shachi::Web::Admin::Resource',
        action   => 'update_edit_status',
    }, { method => 'POST' };
};

sub router { $router }

1;
