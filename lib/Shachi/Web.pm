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
            path => qr{^/(?:images/|js/|css/|docs/|files|xsd/)},
            root => Shachi::Config->root->subdir(Shachi::Config->param('static.root'));

        # logs
        my $log_fh = sub {
            my ($type) = @_;
            my $file = Shachi::Config->root->file(Shachi::Config->param('log.' . $type));
            $file->dir->mkpath;
            my $fh = $file->open('>>') or die "Cannot open $file";
            $fh->autoflush(1);
            $fh;
        };
        my $access_log = $log_fh->('access');
        my $error_log  = $log_fh->('error');

        enable 'AccessLog::Timed',
            logger => sub {
                print $access_log @_;
            },
            format => join(
                "\t",
                "time:%t",
                "host:%h",
                "domain:%V",
                "req:%r",
                "method:%m",
                "path:%U",
                "query:%q",
                "status:%>s",
                "size:%b",
                "referer:%{Referer}i",
                "ua:%{User-Agent}i",
                "taken:%D",
                "runtime:%{X-Runtime}o",
            );

        sub {
            my $env = shift;
            $env->{'psgi.errors'} = $error_log;
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
