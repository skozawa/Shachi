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
};

sub router { $router }

1;
