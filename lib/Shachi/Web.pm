package Shachi::Web;
use strict;
use warnings;

use Plack::Builder;
use Try::Tiny;
use Scalar::Util 'blessed';
use Module::Load qw/load/;

use Shachi::Config;
use Shachi::Context;

sub as_psgi {
    my $class = shift;

    return builder {
        # static files
        enable 'Static',
            path => qr{^/(?:images/|js/|css/|docs/|files/)},
            root => Shachi::Config->root->subdir(Shachi::Config->param('static.root'));

        sub {
            my $env = shift;
            return $class->run($env);
        };
    };
}


sub run {
    my ($class, $env) = @_;

    my $c = Shachi::Context->new(env => $env);

    try {
        my $route = $c->route or die $c->throw_not_found;
        my $controller = $route->{dispatch};
        my $action     = $route->{action} || 'default';

        load $controller;
        $controller->$action($c);
    } catch {
        # TODO
        warn $_;
    };

    return $c->res->finalize;
}

1;
