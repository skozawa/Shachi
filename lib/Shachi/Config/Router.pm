package Shachi::Config::Router;
use strict;
use warnings;
use Router::Simple::Declare qw(connect);

my $router = Router::Simple::Declare::router {
    connect '/' => {
        dispatch => 'Shachi::Web::Index',
    };
};

sub router { $router }

1;
