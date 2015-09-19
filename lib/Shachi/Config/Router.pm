package Shachi::Config::Router;
use strict;
use warnings;
use Router::Simple::Declare qw(connect);

my $router = Router::Simple::Declare::router {
    connect '/' => {
        dispatch => 'Shachi::Web::Index',
    };
    connect '/list/' => {
        dispatch => 'Shachi::Web::Resource',
        action   => 'list',
    };
    connect "/list/detail/{resource_id:[0-9]+}" => {
        dispatch => 'Shachi::Web::Resource',
        action   => 'detail',
    };
};

sub router { $router }

1;
