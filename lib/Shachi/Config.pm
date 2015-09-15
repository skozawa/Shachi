package Shachi::Config;
use strict;
use warnings;

use Config::ENV 'SHACHI_ENV', export => 'config';
use Path::Class qw(file);
use Shachi::Config::Router;

my $Root = file(__FILE__)->dir->parent->parent->absolute;
my $Rooter = Shachi::Config::Router->router;

sub root { $Root }
sub router { $Rooter }

common {
    'db' => {
        shachi => {
            user     => 'root',
            password => '',
            dsn      => 'dbi:mysql:dbname=shachi;host=localhost',
        }
    },

    'static.root' => 'static',
};

config test => {
    'db' => {
        shachi => {
            user     => 'root',
            password => '',
            dsn      => 'dbi:mysql:dbname=shachi_test;host=localhost',
        }
    },
};

1;
